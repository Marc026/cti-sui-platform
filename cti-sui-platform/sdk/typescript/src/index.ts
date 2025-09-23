import { SuiClient, getFullnodeUrl } from '@mysten/sui.js/client';
import { TransactionBlock } from '@mysten/sui.js/transactions';
import { Ed25519Keypair } from '@mysten/sui.js/keypairs/ed25519';
import { normalizeSuiAddress } from '@mysten/sui.js/utils';

export interface CTIPlatformConfig {
  network: 'localnet' | 'devnet' | 'testnet' | 'mainnet';
  packageId: string;
  platformObjectId: string;
}

export interface ThreatIntelligenceData {
  iocHash: Uint8Array;
  threatType: string;
  severity: number;
  confidenceScore: number;
  stixPattern: string;
  mitreTechniques: string[];
  expirationHours: number;
}

export interface ParticipantProfile {
  address: string;
  organization: string;
  reputationScore: number;
  contributions: number;
  successfulValidations: number;
  accessLevel: number;
  joinDate: number;
}

export interface PlatformStats {
  totalSubmissions: number;
  totalValidations: number;
  feePoolBalance: number;
}

export interface ValidationData {
  qualityScore: number;
  isAccurate: boolean;
  comments: string;
}

export class CTIPlatformSDK {
  private client: SuiClient;
  private config: CTIPlatformConfig;
  
  constructor(config: CTIPlatformConfig) {
    this.config = config;
    this.client = new SuiClient({ 
      url: getFullnodeUrl(config.network) 
    });
  }

  /**
   * Register a new participant in the CTI platform
   */
  async registerParticipant(
    keypair: Ed25519Keypair,
    organization: string,
    gasBudget: number = 10_000_000
  ): Promise<string> {
    const tx = new TransactionBlock();
    
    tx.moveCall({
      target: `${this.config.packageId}::threat_intelligence::register_participant`,
      arguments: [
        tx.object(this.config.platformObjectId),
        tx.pure(organization),
        tx.object('0x6'), // Clock object
      ],
    });

    const result = await this.client.signAndExecuteTransactionBlock({
      signer: keypair,
      transactionBlock: tx,
      options: { 
        showEffects: true, 
        showEvents: true,
        showObjectChanges: true
      }
    });

    if (result.effects?.status?.status === 'success') {
      return result.digest;
    } else {
      throw new Error(`Registration failed: ${result.effects?.status?.error}`);
    }
  }

  /**
   * Submit new threat intelligence
   */
  async submitIntelligence(
    keypair: Ed25519Keypair,
    profileObjectId: string,
    intelligenceData: ThreatIntelligenceData,
    submissionFee: string,
    gasBudget: number = 20_000_000
  ): Promise<string> {
    const tx = new TransactionBlock();

    const [feeCoin] = tx.splitCoins(tx.gas, [tx.pure(submissionFee)]);

    tx.moveCall({
      target: `${this.config.packageId}::threat_intelligence::submit_intelligence`,
      arguments: [
        tx.object(this.config.platformObjectId),
        tx.object(profileObjectId),
        tx.pure(Array.from(intelligenceData.iocHash)),
        tx.pure(intelligenceData.threatType),
        tx.pure(intelligenceData.severity),
        tx.pure(intelligenceData.confidenceScore),
        tx.pure(intelligenceData.stixPattern),
        tx.pure(intelligenceData.mitreTechniques),
        tx.pure(intelligenceData.expirationHours),
        feeCoin,
        tx.object('0x6'), // Clock object
      ],
    });

    const result = await this.client.signAndExecuteTransactionBlock({
      signer: keypair,
      transactionBlock: tx,
      options: { 
        showEffects: true, 
        showEvents: true,
        showObjectChanges: true
      }
    });

    if (result.effects?.status?.status === 'success') {
      return result.digest;
    } else {
      throw new Error(`Intelligence submission failed: ${result.effects?.status?.error}`);
    }
  }

  /**
   * Validate threat intelligence
   */
  async validateIntelligence(
    keypair: Ed25519Keypair,
    validatorProfileId: string,
    intelligenceObjectId: string,
    validationData: ValidationData,
    gasBudget: number = 15_000_000
  ): Promise<string> {
    const tx = new TransactionBlock();

    tx.moveCall({
      target: `${this.config.packageId}::threat_intelligence::validate_intelligence`,
      arguments: [
        tx.object(this.config.platformObjectId),
        tx.object(validatorProfileId),
        tx.object(intelligenceObjectId),
        tx.pure(validationData.qualityScore),
        tx.pure(validationData.isAccurate),
        tx.pure(validationData.comments),
        tx.object('0x6'), // Clock object
      ],
    });

    const result = await this.client.signAndExecuteTransactionBlock({
      signer: keypair,
      transactionBlock: tx,
      options: { 
        showEffects: true, 
        showEvents: true 
      }
    });

    if (result.effects?.status?.status === 'success') {
      return result.digest;
    } else {
      throw new Error(`Validation failed: ${result.effects?.status?.error}`);
    }
  }

  /**
   * Grant access to threat intelligence
   */
  async grantAccess(
    keypair: Ed25519Keypair,
    intelligenceObjectId: string,
    requestorProfileId: string,
    accessDurationHours: number,
    gasBudget: number = 10_000_000
  ): Promise<string> {
    const tx = new TransactionBlock();

    // First get the requestor profile to pass to the function
    const requestorProfile = await this.client.getObject({
      id: requestorProfileId,
      options: { showContent: true }
    });

    tx.moveCall({
      target: `${this.config.packageId}::threat_intelligence::grant_access`,
      arguments: [
        tx.object(intelligenceObjectId),
        tx.object(requestorProfileId),
        tx.pure(accessDurationHours),
        tx.object('0x6'), // Clock object
      ],
    });

    const result = await this.client.signAndExecuteTransactionBlock({
      signer: keypair,
      transactionBlock: tx,
      options: { 
        showEffects: true, 
        showEvents: true 
      }
    });

    if (result.effects?.status?.status === 'success') {
      return result.digest;
    } else {
      throw new Error(`Access grant failed: ${result.effects?.status?.error}`);
    }
  }

  /**
   * Get platform statistics
   */
  async getPlatformStats(): Promise<PlatformStats> {
    const result = await this.client.devInspectTransactionBlock({
      transactionBlock: (() => {
        const tx = new TransactionBlock();
        tx.moveCall({
          target: `${this.config.packageId}::threat_intelligence::get_platform_stats`,
          arguments: [tx.object(this.config.platformObjectId)],
        });
        return tx;
      })(),
      sender: normalizeSuiAddress('0x0'),
    });

    if (result.results?.[0]?.returnValues) {
      const [submissions, validations, feePool] = result.results[0].returnValues.map(
        (val) => parseInt(val[0])
      );
      return {
        totalSubmissions: submissions,
        totalValidations: validations,
        feePoolBalance: feePool,
      };
    }

    throw new Error('Failed to fetch platform statistics');
  }

  /**
   * Get participant profile information
   */
  async getParticipantProfile(profileObjectId: string): Promise<ParticipantProfile | null> {
    try {
      const result = await this.client.getObject({
        id: profileObjectId,
        options: { showContent: true }
      });

      if (result.data?.content && 'fields' in result.data.content) {
        const fields = result.data.content.fields as any;
        return {
          address: fields.address,
          organization: fields.organization,
          reputationScore: parseInt(fields.reputation_score),
          contributions: parseInt(fields.contributions),
          successfulValidations: parseInt(fields.successful_validations),
          accessLevel: parseInt(fields.access_level),
          joinDate: parseInt(fields.join_date),
        };
      }
      return null;
    } catch (error) {
      console.error('Error fetching participant profile:', error);
      return null;
    }
  }

  /**
   * Get threat intelligence object details
   */
  async getThreatIntelligence(intelligenceObjectId: string) {
    try {
      const result = await this.client.getObject({
        id: intelligenceObjectId,
        options: { showContent: true }
      });

      if (result.data?.content && 'fields' in result.data.content) {
        const fields = result.data.content.fields as any;
        return {
          id: result.data.objectId,
          iocHash: fields.ioc_hash,
          threatType: fields.threat_type,
          severity: parseInt(fields.severity),
          confidenceScore: parseInt(fields.confidence_score),
          submitter: fields.submitter,
          submissionTime: parseInt(fields.submission_time),
          expirationTime: parseInt(fields.expiration_time),
          validationCount: parseInt(fields.validation_count),
          validationScore: parseInt(fields.validation_score),
          isVerified: fields.is_verified,
          stixPattern: fields.stix_pattern,
          mitreTechniques: fields.mitre_techniques,
        };
      }
      return null;
    } catch (error) {
      console.error('Error fetching threat intelligence:', error);
      return null;
    }
  }

  /**
   * Subscribe to platform events
   */
  async subscribeToEvents(
    eventCallback: (event: any) => void,
    eventTypes: string[] = []
  ): Promise<() => void> {
    const eventFilter = { 
      Package: this.config.packageId 
    };

    const unsubscribe = await this.client.subscribeEvent({
      filter: eventFilter,
      onMessage: (event) => {
        const processedEvent = {
          type: event.type,
          timestamp: Date.now(),
          data: event.parsedJson,
          transactionDigest: event.transactionDigest
        };
        
        // Filter by event types if specified
        if (eventTypes.length === 0 || eventTypes.some(type => event.type.includes(type))) {
          eventCallback(processedEvent);
        }
      },
    });

    return unsubscribe;
  }

  /**
   * Get recent events from the platform
   */
  async getRecentEvents(limit: number = 100): Promise<any[]> {
    try {
      const events = await this.client.queryEvents({
        query: { Package: this.config.packageId },
        limit,
        order: 'descending'
      });

      return events.data.map(event => ({
        type: event.type,
        timestamp: parseInt(event.timestampMs || '0'),
        data: event.parsedJson,
        transactionDigest: event.transactionDigest,
        id: event.id
      }));
    } catch (error) {
      console.error('Error fetching recent events:', error);
      return [];
    }
  }

  /**
   * Check if a participant is registered
   */
  async isParticipantRegistered(participantAddress: string): Promise<boolean> {
    const result = await this.client.devInspectTransactionBlock({
      transactionBlock: (() => {
        const tx = new TransactionBlock();
        tx.moveCall({
          target: `${this.config.packageId}::threat_intelligence::is_participant_registered`,
          arguments: [
            tx.object(this.config.platformObjectId),
            tx.pure(participantAddress)
          ],
        });
        return tx;
      })(),
      sender: normalizeSuiAddress('0x0'),
    });

    if (result.results?.[0]?.returnValues?.[0]) {
      return result.results[0].returnValues[0][0] === 1;
    }

    return false;
  }

  /**
   * Get owned objects by address (profiles, intelligence, etc.)
   */
  async getOwnedObjects(address: string) {
    try {
      const result = await this.client.getOwnedObjects({
        owner: address,
        filter: {
          Package: this.config.packageId
        },
        options: {
          showContent: true,
          showType: true
        }
      });

      return result.data.map(obj => ({
        objectId: obj.data?.objectId,
        type: obj.data?.type,
        content: obj.data?.content
      }));
    } catch (error) {
      console.error('Error fetching owned objects:', error);
      return [];
    }
  }
}

// Analytics and utility class
export class CTIAnalytics {
  private sdk: CTIPlatformSDK;

  constructor(sdk: CTIPlatformSDK) {
    this.sdk = sdk;
  }

  /**
   * Analyze threat intelligence trends
   */
  async analyzeThreatTrends(timeframeHours: number = 24): Promise<{
    threatTypes: Record<string, number>;
    severityDistribution: Record<number, number>;
    submissionTrend: Array<{ time: number; count: number }>;
  }> {
    const events = await this.sdk.getRecentEvents(1000);
    const currentTime = Date.now();
    const cutoffTime = currentTime - (timeframeHours * 60 * 60 * 1000);

    const submissionEvents = events.filter(event => 
      event.type.includes('IntelligenceSubmitted') &&
      parseInt(event.data?.submission_time || '0') > cutoffTime
    );

    const threatTypes: Record<string, number> = {};
    const severityDistribution: Record<number, number> = {};
    const hourlySubmissions: Record<number, number> = {};

    submissionEvents.forEach(event => {
      const data = event.data;
      if (data) {
        // Count threat types
        threatTypes[data.threat_type] = (threatTypes[data.threat_type] || 0) + 1;
        
        // Count severity distribution
        if (data.severity) {
          severityDistribution[data.severity] = (severityDistribution[data.severity] || 0) + 1;
        }

        // Count hourly submissions
        const hour = Math.floor(parseInt(data.submission_time) / (60 * 60 * 1000));
        hourlySubmissions[hour] = (hourlySubmissions[hour] || 0) + 1;
      }
    });

    const submissionTrend = Object.entries(hourlySubmissions)
      .map(([hour, count]) => ({
        time: parseInt(hour) * 60 * 60 * 1000,
        count,
      }))
      .sort((a, b) => a.time - b.time);

    return {
      threatTypes,
      severityDistribution,
      submissionTrend,
    };
  }

  /**
   * Generate platform health report
   */
  async generateHealthReport(): Promise<{
    platformStats: any;
    recentActivity: any;
    topContributors: any;
  }> {
    const [platformStats, events] = await Promise.all([
      this.sdk.getPlatformStats(),
      this.sdk.getRecentEvents(100)
    ]);

    const last24Hours = Date.now() - (24 * 60 * 60 * 1000);
    const recentEvents = events.filter(e => e.timestamp > last24Hours);

    return {
      platformStats,
      recentActivity: {
        totalEvents: recentEvents.length,
        submissions: recentEvents.filter(e => e.type.includes('Submitted')).length,
        validations: recentEvents.filter(e => e.type.includes('Validated')).length,
      },
      topContributors: this.analyzeTopContributors(events),
    };
  }

  private analyzeTopContributors(events: any[]) {
    const contributors: Record<string, number> = {};
    
    events.forEach(event => {
      if (event.type.includes('Submitted') && event.data?.submitter) {
        contributors[event.data.submitter] = (contributors[event.data.submitter] || 0) + 1;
      }
    });

    return Object.entries(contributors)
      .sort(([,a], [,b]) => b - a)
      .slice(0, 10)
      .map(([address, count]) => ({ address, submissions: count }));
  }
}

export default CTIPlatformSDK;