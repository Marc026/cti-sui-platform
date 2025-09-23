"""
SIEM Integration Module for CTI Platform
Supports multiple SIEM platforms including Splunk, QRadar, ArcSight, and Sentinel
"""

import json
import requests
import asyncio
import logging
from typing import Dict, Any, List, Optional, Union
from datetime import datetime, timezone
from dataclasses import dataclass
from enum import Enum
import hashlib
import base64

logger = logging.getLogger(__name__)

class SIEMType(Enum):
    SPLUNK = "splunk"
    QRADAR = "qradar"
    ARCSIGHT = "arcsight"
    SENTINEL = "sentinel"
    ELASTIC = "elastic"
    GENERIC = "generic"

@dataclass
class SIEMConfig:
    """Configuration for SIEM connection"""
    siem_type: SIEMType
    endpoint: str
    api_key: str
    username: Optional[str] = None
    password: Optional[str] = None
    verify_ssl: bool = True
    timeout: int = 30
    max_retries: int = 3

@dataclass
class CTIAlert:
    """Standardized CTI alert format"""
    id: str
    timestamp: str
    severity: str
    threat_type: str
    confidence_score: int
    ioc_hash: str
    stix_pattern: str
    mitre_techniques: List[str]
    submitter: str
    is_verified: bool
    description: str
    source: str = "CTI_Platform_Sui"

class SIEMConnector:
    """Base SIEM connector with common functionality"""
    
    def __init__(self, config: SIEMConfig):
        self.config = config
        self.session = requests.Session()
        self.session.verify = config.verify_ssl
        
        # Set authentication headers
        if config.api_key:
            self.session.headers.update({
                'Authorization': f'Bearer {config.api_key}',
                'Content-Type': 'application/json'
            })
    
    def _map_severity(self, sui_severity: int) -> str:
        """Map Sui severity (1-10) to SIEM severity levels"""
        if sui_severity >= 8:
            return "critical"
        elif sui_severity >= 6:
            return "high"
        elif sui_severity >= 4:
            return "medium"
        else:
            return "low"
    
    def _map_confidence(self, confidence_score: int) -> str:
        """Map confidence score to qualitative levels"""
        if confidence_score >= 80:
            return "high"
        elif confidence_score >= 60:
            return "medium"
        else:
            return "low"
    
    async def push_intelligence(self, intelligence_data: Dict[str, Any]) -> bool:
        """Push CTI data to SIEM - to be implemented by specific connectors"""
        raise NotImplementedError("Subclasses must implement push_intelligence")
    
    async def test_connection(self) -> bool:
        """Test SIEM connectivity"""
        try:
            response = self.session.get(
                f"{self.config.endpoint}/health",
                timeout=self.config.timeout
            )
            return response.status_code == 200
        except Exception as e:
            logger.error(f"SIEM connection test failed: {e}")
            return False

class SplunkConnector(SIEMConnector):
    """Splunk-specific SIEM connector"""
    
    def __init__(self, config: SIEMConfig):
        super().__init__(config)
        self.session.headers.update({
            'Authorization': f'Splunk {config.api_key}'
        })
    
    async def push_intelligence(self, intelligence_data: Dict[str, Any]) -> bool:
        """Push CTI data to Splunk HEC (HTTP Event Collector)"""
        try:
            # Format for Splunk HEC
            splunk_event = {
                "time": int(datetime.now().timestamp()),
                "source": "cti_platform_sui",
                "sourcetype": "threat_intelligence",
                "index": "security",
                "event": {
                    "threat_id": intelligence_data.get("id"),
                    "timestamp": intelligence_data.get("submission_time"),
                    "severity": self._map_severity(intelligence_data.get("severity", 1)),
                    "threat_type": intelligence_data.get("threat_type"),
                    "confidence": self._map_confidence(intelligence_data.get("confidence_score", 0)),
                    "indicators": {
                        "ioc_hash": intelligence_data.get("ioc_hash"),
                        "stix_pattern": intelligence_data.get("stix_pattern"),
                        "mitre_techniques": intelligence_data.get("mitre_techniques", [])
                    },
                    "submitter": intelligence_data.get("submitter"),
                    "verified": intelligence_data.get("is_verified", False),
                    "validation_count": intelligence_data.get("validation_count", 0),
                    "blockchain_source": "sui",
                    "platform": "cti_sharing_platform"
                }
            }
            
            response = self.session.post(
                f"{self.config.endpoint}/services/collector/event",
                data=json.dumps(splunk_event),
                timeout=self.config.timeout
            )
            
            if response.status_code == 200:
                logger.info(f"Successfully pushed intelligence to Splunk: {intelligence_data.get('threat_type')}")
                return True
            else:
                logger.error(f"Splunk push failed: {response.status_code} - {response.text}")
                return False
                
        except Exception as e:
            logger.error(f"Exception pushing to Splunk: {e}")
            return False

class QRadarConnector(SIEMConnector):
    """IBM QRadar-specific SIEM connector"""
    
    def __init__(self, config: SIEMConfig):
        super().__init__(config)
        self.session.headers.update({
            'SEC': config.api_key,
            'Version': '12.0'
        })
    
    async def push_intelligence(self, intelligence_data: Dict[str, Any]) -> bool:
        """Push CTI data to QRadar as custom events"""
        try:
            # QRadar custom event format
            qradar_event = {
                "events": [{
                    "qid": 99999,  # Custom QID for CTI events
                    "severity": self._qradar_severity_mapping(intelligence_data.get("severity", 1)),
                    "credibility": min(10, intelligence_data.get("confidence_score", 0) // 10),
                    "relevance": 10 if intelligence_data.get("is_verified") else 5,
                    "properties": {
                        "threat_type": intelligence_data.get("threat_type"),
                        "ioc_hash": intelligence_data.get("ioc_hash"),
                        "stix_pattern": intelligence_data.get("stix_pattern"),
                        "mitre_techniques": ",".join(intelligence_data.get("mitre_techniques", [])),
                        "submitter": intelligence_data.get("submitter"),
                        "blockchain_tx": intelligence_data.get("transaction_hash", ""),
                        "sui_platform": "true"
                    }
                }]
            }
            
            response = self.session.post(
                f"{self.config.endpoint}/api/siem/events",
                data=json.dumps(qradar_event),
                timeout=self.config.timeout
            )
            
            if response.status_code in [200, 201]:
                logger.info(f"Successfully pushed intelligence to QRadar: {intelligence_data.get('threat_type')}")
                return True
            else:
                logger.error(f"QRadar push failed: {response.status_code} - {response.text}")
                return False
                
        except Exception as e:
            logger.error(f"Exception pushing to QRadar: {e}")
            return False
    
    def _qradar_severity_mapping(self, sui_severity: int) -> int:
        """Map to QRadar severity scale (1-10)"""
        return min(10, max(1, sui_severity))

class SentinelConnector(SIEMConnector):
    """Microsoft Sentinel-specific SIEM connector"""
    
    def __init__(self, config: SIEMConfig):
        super().__init__(config)
        # Sentinel uses workspace ID and shared key
        self.workspace_id = config.username  # Using username field for workspace ID
        self.shared_key = config.api_key
    
    async def push_intelligence(self, intelligence_data: Dict[str, Any]) -> bool:
        """Push CTI data to Sentinel via Data Collector API"""
        try:
            # Sentinel log format
            log_data = [{
                "TimeGenerated": datetime.now(timezone.utc).isoformat(),
                "ThreatType": intelligence_data.get("threat_type"),
                "Severity": self._map_severity(intelligence_data.get("severity", 1)),
                "ConfidenceScore": intelligence_data.get("confidence_score", 0),
                "IOCHash": intelligence_data.get("ioc_hash"),
                "STIXPattern": intelligence_data.get("stix_pattern"),
                "MITRETechniques": ",".join(intelligence_data.get("mitre_techniques", [])),
                "Submitter": intelligence_data.get("submitter"),
                "IsVerified": intelligence_data.get("is_verified", False),
                "ValidationCount": intelligence_data.get("validation_count", 0),
                "BlockchainPlatform": "Sui",
                "CTIPlatform": "SuiCTISharing"
            }]
            
            # Build signature for Sentinel
            body = json.dumps(log_data)
            date = datetime.now(timezone.utc).strftime('%a, %d %b %Y %H:%M:%S GMT')
            string_to_hash = f"POST\n{len(body)}\napplication/json\nx-ms-date:{date}\n/api/logs"
            
            signature = self._build_signature(string_to_hash, self.shared_key)
            
            headers = {
                'Content-Type': 'application/json',
                'Authorization': f'SharedKey {self.workspace_id}:{signature}',
                'Log-Type': 'CTIThreatIntelligence',
                'x-ms-date': date
            }
            
            response = self.session.post(
                f"https://{self.workspace_id}.ods.opinsights.azure.com/api/logs?api-version=2016-04-01",
                data=body,
                headers=headers,
                timeout=self.config.timeout
            )
            
            if response.status_code == 200:
                logger.info(f"Successfully pushed intelligence to Sentinel: {intelligence_data.get('threat_type')}")
                return True
            else:
                logger.error(f"Sentinel push failed: {response.status_code} - {response.text}")
                return False
                
        except Exception as e:
            logger.error(f"Exception pushing to Sentinel: {e}")
            return False
    
    def _build_signature(self, message: str, secret: str) -> str:
        """Build authentication signature for Sentinel"""
        import hmac
        
        bytes_to_sign = message.encode('utf-8')
        decoded_key = base64.b64decode(secret)
        encoded_hash = base64.b64encode(hmac.new(decoded_key, bytes_to_sign, hashlib.sha256).digest())
        return encoded_hash.decode('utf-8')

class ElasticConnector(SIEMConnector):
    """Elastic SIEM connector"""
    
    def __init__(self, config: SIEMConfig):
        super().__init__(config)
        if config.username and config.password:
            # Basic auth
            self.session.auth = (config.username, config.password)
    
    async def push_intelligence(self, intelligence_data: Dict[str, Any]) -> bool:
        """Push CTI data to Elasticsearch"""
        try:
            # Elastic document format
            doc = {
                "@timestamp": datetime.now(timezone.utc).isoformat(),
                "event": {
                    "kind": "enrichment",
                    "category": ["threat"],
                    "type": ["indicator"],
                    "dataset": "cti.sui_platform"
                },
                "threat": {
                    "indicator": {
                        "type": intelligence_data.get("threat_type"),
                        "confidence": self._map_confidence(intelligence_data.get("confidence_score", 0)),
                        "marking": {
                            "verified": intelligence_data.get("is_verified", False)
                        }
                    }
                },
                "cti_platform": {
                    "blockchain": "sui",
                    "submitter": intelligence_data.get("submitter"),
                    "validation_count": intelligence_data.get("validation_count", 0),
                    "ioc_hash": intelligence_data.get("ioc_hash"),
                    "stix_pattern": intelligence_data.get("stix_pattern"),
                    "mitre_techniques": intelligence_data.get("mitre_techniques", [])
                },
                "log": {
                    "level": self._map_severity(intelligence_data.get("severity", 1))
                }
            }
            
            # Generate document ID
            doc_id = hashlib.sha256(
                f"{intelligence_data.get('ioc_hash', '')}{intelligence_data.get('submitter', '')}".encode()
            ).hexdigest()
            
            response = self.session.put(
                f"{self.config.endpoint}/cti-intelligence/_doc/{doc_id}",
                data=json.dumps(doc),
                timeout=self.config.timeout
            )
            
            if response.status_code in [200, 201]:
                logger.info(f"Successfully pushed intelligence to Elastic: {intelligence_data.get('threat_type')}")
                return True
            else:
                logger.error(f"Elastic push failed: {response.status_code} - {response.text}")
                return False
                
        except Exception as e:
            logger.error(f"Exception pushing to Elastic: {e}")
            return False

class CTISIEMIntegration:
    """Main CTI-SIEM integration orchestrator"""
    
    def __init__(self):
        self.connectors: Dict[str, SIEMConnector] = {}
        self.config: Dict[str, Any] = {}
    
    def add_siem_connector(self, name: str, connector: SIEMConnector):
        """Add a SIEM connector"""
        self.connectors[name] = connector
        logger.info(f"Added SIEM connector: {name}")
    
    def remove_siem_connector(self, name: str):
        """Remove a SIEM connector"""
        if name in self.connectors:
            del self.connectors[name]
            logger.info(f"Removed SIEM connector: {name}")
    
    async def broadcast_intelligence(self, intelligence_data: Dict[str, Any], 
                                   target_siems: Optional[List[str]] = None) -> Dict[str, bool]:
        """Broadcast CTI to all or specified SIEM systems"""
        results = {}
        
        target_connectors = self.connectors
        if target_siems:
            target_connectors = {k: v for k, v in self.connectors.items() if k in target_siems}
        
        # Broadcast to all target SIEMs concurrently
        tasks = []
        for name, connector in target_connectors.items():
            task = asyncio.create_task(
                self._safe_push_intelligence(name, connector, intelligence_data)
            )
            tasks.append(task)
        
        # Wait for all pushes to complete
        push_results = await asyncio.gather(*tasks, return_exceptions=True)
        
        # Compile results
        for i, (name, _) in enumerate(target_connectors.items()):
            result = push_results[i]
            if isinstance(result, Exception):
                logger.error(f"SIEM {name} push failed with exception: {result}")
                results[name] = False
            else:
                results[name] = result
        
        success_count = sum(1 for success in results.values() if success)
        logger.info(f"Intelligence broadcast completed: {success_count}/{len(results)} successful")
        
        return results
    
    async def _safe_push_intelligence(self, name: str, connector: SIEMConnector, 
                                    intelligence_data: Dict[str, Any]) -> bool:
        """Safely push intelligence with error handling"""
        try:
            return await connector.push_intelligence(intelligence_data)
        except Exception as e:
            logger.error(f"Error pushing to SIEM {name}: {e}")
            return False
    
    async def test_all_connections(self) -> Dict[str, bool]:
        """Test connectivity to all configured SIEMs"""
        results = {}
        
        for name, connector in self.connectors.items():
            try:
                results[name] = await connector.test_connection()
            except Exception as e:
                logger.error(f"Connection test failed for {name}: {e}")
                results[name] = False
        
        return results
    
    def get_connector_status(self) -> Dict[str, Dict[str, Any]]:
        """Get status of all connectors"""
        status = {}
        
        for name, connector in self.connectors.items():
            status[name] = {
                "siem_type": connector.config.siem_type.value,
                "endpoint": connector.config.endpoint,
                "verify_ssl": connector.config.verify_ssl,
                "timeout": connector.config.timeout
            }
        
        return status

# Factory function for creating SIEM connectors
def create_siem_connector(siem_type: SIEMType, config: SIEMConfig) -> SIEMConnector:
    """Factory function to create appropriate SIEM connector"""
    
    connector_map = {
        SIEMType.SPLUNK: SplunkConnector,
        SIEMType.QRADAR: QRadarConnector,
        SIEMType.SENTINEL: SentinelConnector,
        SIEMType.ELASTIC: ElasticConnector,
        SIEMType.GENERIC: SIEMConnector
    }
    
    connector_class = connector_map.get(siem_type, SIEMConnector)
    return connector_class(config)

# Example usage and configuration
async def example_integration():
    """Example of how to use the SIEM integration"""
    
    # Create SIEM integration orchestrator
    integration = CTISIEMIntegration()
    
    # Configure Splunk connector
    splunk_config = SIEMConfig(
        siem_type=SIEMType.SPLUNK,
        endpoint="https://splunk.company.com:8088",
        api_key="your-hec-token-here"
    )
    splunk_connector = create_siem_connector(SIEMType.SPLUNK, splunk_config)
    integration.add_siem_connector("primary_splunk", splunk_connector)
    
    # Configure Sentinel connector
    sentinel_config = SIEMConfig(
        siem_type=SIEMType.SENTINEL,
        endpoint="",  # Not used for Sentinel
        username="your-workspace-id",
        api_key="your-shared-key"
    )
    sentinel_connector = create_siem_connector(SIEMType.SENTINEL, sentinel_config)
    integration.add_siem_connector("azure_sentinel", sentinel_connector)
    
    # Test connections
    connection_results = await integration.test_all_connections()
    print("Connection test results:", connection_results)
    
    # Example CTI data
    sample_intelligence = {
        "id": "cti_001",
        "threat_type": "malware",
        "severity": 8,
        "confidence_score": 85,
        "submission_time": datetime.now().isoformat(),
        "is_verified": True,
        "ioc_hash": "abc123def456",
        "stix_pattern": '[file:hashes.MD5 = "abc123def456"]',
        "mitre_techniques": ["T1055", "T1003"],
        "submitter": "0x123...abc",
        "validation_count": 3
    }
    
    # Broadcast to all SIEMs
    broadcast_results = await integration.broadcast_intelligence(sample_intelligence)
    print("Broadcast results:", broadcast_results)

if __name__ == "__main__":
    asyncio.run(example_integration())