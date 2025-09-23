const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const compression = require('compression');
const { SuiClient, getFullnodeUrl } = require('@mysten/sui.js/client');
const { TransactionBlock } = require('@mysten/sui.js/transactions');
const { Ed25519Keypair } = require('@mysten/sui.js/keypairs/ed25519');
const Redis = require('redis');
const winston = require('winston');

// Load environment configuration
require('dotenv').config();

// Configure logging
const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.errors({ stack: true }),
    winston.format.json()
  ),
  defaultMeta: { service: 'cti-api' },
  transports: [
    new winston.transports.File({ filename: 'logs/error.log', level: 'error' }),
    new winston.transports.File({ filename: 'logs/combined.log' }),
    new winston.transports.Console({
      format: winston.format.simple()
    })
  ]
});

class CTIAPIServer {
  constructor() {
    this.app = express();
    this.suiClient = null;
    this.redisClient = null;
    this.config = this.loadConfig();
    
    this.initializeMiddleware();
    this.initializeRoutes();
    this.initializeErrorHandling();
  }

  loadConfig() {
    return {
      port: process.env.PORT || 3000,
      nodeEnv: process.env.NODE_ENV || 'development',
      suiNetwork: process.env.SUI_NETWORK || 'testnet',
      packageId: process.env.PACKAGE_ID || '',
      platformObjectId: process.env.PLATFORM_OBJECT_ID || '',
      redisUrl: process.env.REDIS_URL || 'redis://localhost:6379',
      jwtSecret: process.env.JWT_SECRET || 'your-secret-key',
      corsOrigin: process.env.CORS_ORIGIN || '*',
      rateLimitWindow: parseInt(process.env.RATE_LIMIT_WINDOW) || 15 * 60 * 1000, // 15 minutes
      rateLimitMax: parseInt(process.env.RATE_LIMIT_MAX) || 1000
    };
  }

  async initialize() {
    try {
      // Initialize Sui client
      this.suiClient = new SuiClient({ 
        url: getFullnodeUrl(this.config.suiNetwork) 
      });
      
      // Initialize Redis client
      this.redisClient = Redis.createClient({ url: this.config.redisUrl });
      await this.redisClient.connect();
      
      logger.info('CTI API Server initialized successfully');
    } catch (error) {
      logger.error('Failed to initialize CTI API Server:', error);
      throw error;
    }
  }

  initializeMiddleware() {
    // Security middleware
    this.app.use(helmet());
    
    // Compression
    this.app.use(compression());
    
    // CORS
    this.app.use(cors({
      origin: this.config.corsOrigin,
      credentials: true
    }));
    
    // Rate limiting
    const limiter = rateLimit({
      windowMs: this.config.rateLimitWindow,
      max: this.config.rateLimitMax,
      message: 'Too many requests from this IP, please try again later.'
    });
    this.app.use('/api/', limiter);
    
    // Body parsing
    this.app.use(express.json({ limit: '10mb' }));
    this.app.use(express.urlencoded({ extended: true }));
    
    // Request logging
    this.app.use((req, res, next) => {
      logger.info(`${req.method} ${req.path} - ${req.ip}`);
      next();
    });
  }

  initializeRoutes() {
    // Health check
    this.app.get('/health', this.healthCheck.bind(this));
    
    // API routes
    this.app.use('/api/v1', this.createAPIRoutes());
    
    // Serve static files for documentation
    this.app.use('/docs', express.static('docs'));
    
    // Default route
    this.app.get('/', (req, res) => {
      res.json({
        service: 'CTI Platform API',
        version: '1.0.0',
        status: 'running',
        documentation: '/docs'
      });
    });
  }

  createAPIRoutes() {
    const router = express.Router();
    
    // Platform statistics
    router.get('/stats', this.getPlatformStats.bind(this));
    
    // Participant management
    router.post('/participants/register', this.registerParticipant.bind(this));
    router.get('/participants/:address', this.getParticipant.bind(this));
    router.get('/participants/:address/profile', this.getParticipantProfile.bind(this));
    
    // Threat intelligence
    router.post('/intelligence/submit', this.submitIntelligence.bind(this));
    router.get('/intelligence/:id', this.getIntelligence.bind(this));
    router.get('/intelligence', this.queryIntelligence.bind(this));
    router.post('/intelligence/:id/validate', this.validateIntelligence.bind(this));
    
    // Access control
    router.post('/intelligence/:id/grant-access', this.grantAccess.bind(this));
    router.get('/access-capabilities/:address', this.getAccessCapabilities.bind(this));
    
    // Analytics
    router.get('/analytics/trends', this.getThreatTrends.bind(this));
    router.get('/analytics/reputation', this.getReputationStats.bind(this));
    router.get('/analytics/activity', this.getActivityStats.bind(this));
    
    // Events and monitoring
    router.get('/events', this.getRecentEvents.bind(this));
    router.get('/events/stream', this.streamEvents.bind(this));
    
    // Search and filters
    router.get('/search', this.searchIntelligence.bind(this));
    router.get('/filters/threat-types', this.getThreatTypes.bind(this));
    router.get('/filters/mitre-techniques', this.getMitreTechniques.bind(this));
    
    return router;
  }

  async healthCheck(req, res) {
    try {
      const health = {
        status: 'healthy',
        timestamp: new Date().toISOString(),
        version: '1.0.0',
        services: {}
      };

      // Check Sui connection
      try {
        await this.suiClient.getLatestSuiSystemState();
        health.services.sui = 'connected';
      } catch (error) {
        health.services.sui = 'disconnected';
        health.status = 'degraded';
      }

      // Check Redis connection
      try {
        await this.redisClient.ping();
        health.services.redis = 'connected';
      } catch (error) {
        health.services.redis = 'disconnected';
        health.status = 'degraded';
      }

      res.json(health);
    } catch (error) {
      logger.error('Health check failed:', error);
      res.status(500).json({
        status: 'unhealthy',
        error: error.message
      });
    }
  }

  async getPlatformStats(req, res) {
    try {
      // Check cache first
      const cacheKey = 'platform_stats';
      const cached = await this.redisClient.get(cacheKey);
      
      if (cached) {
        return res.json(JSON.parse(cached));
      }

      // Get stats from blockchain
      const result = await this.suiClient.devInspectTransactionBlock({
        transactionBlock: (() => {
          const tx = new TransactionBlock();
          tx.moveCall({
            target: `${this.config.packageId}::threat_intelligence::get_platform_stats`,
            arguments: [tx.object(this.config.platformObjectId)],
          });
          return tx;
        })(),
        sender: '0x0000000000000000000000000000000000000000000000000000000000000000',
      });

      if (result.results?.[0]?.returnValues) {
        const [submissions, validations, feePool] = result.results[0].returnValues.map(
          (val) => parseInt(val[0])
        );
        
        const stats = {
          totalSubmissions: submissions,
          totalValidations: validations,
          feePoolBalance: feePool,
          timestamp: new Date().toISOString()
        };

        // Cache for 5 minutes
        await this.redisClient.setEx(cacheKey, 300, JSON.stringify(stats));
        
        res.json(stats);
      } else {
        throw new Error('Failed to fetch platform statistics');
      }
    } catch (error) {
      logger.error('Error fetching platform stats:', error);
      res.status(500).json({ error: 'Failed to fetch platform statistics' });
    }
  }

  async registerParticipant(req, res) {
    try {
      const { organization, privateKey } = req.body;
      
      if (!organization || !privateKey) {
        return res.status(400).json({ 
          error: 'Organization and private key are required' 
        });
      }

      const keypair = Ed25519Keypair.fromSecretKey(privateKey);
      const tx = new TransactionBlock();
      
      tx.moveCall({
        target: `${this.config.packageId}::threat_intelligence::register_participant`,
        arguments: [
          tx.object(this.config.platformObjectId),
          tx.pure(organization),
          tx.object('0x6'), // Clock object
        ],
      });

      const result = await this.suiClient.signAndExecuteTransactionBlock({
        signer: keypair,
        transactionBlock: tx,
        options: { 
          showEffects: true, 
          showEvents: true,
          showObjectChanges: true
        }
      });

      if (result.effects?.status?.status === 'success') {
        const response = {
          success: true,
          transactionDigest: result.digest,
          participantAddress: keypair.getPublicKey().toSuiAddress(),
          organization: organization,
          timestamp: new Date().toISOString()
        };
        
        // Extract profile object ID from object changes
        const profileObject = result.objectChanges?.find(
          change => change.type === 'created' && 
          change.objectType?.includes('ParticipantProfile')
        );
        
        if (profileObject) {
          response.profileObjectId = profileObject.objectId;
        }
        
        res.json(response);
      } else {
        throw new Error(result.effects?.status?.error || 'Registration failed');
      }
    } catch (error) {
      logger.error('Registration error:', error);
      res.status(500).json({ 
        error: 'Registration failed', 
        details: error.message 
      });
    }
  }

  async submitIntelligence(req, res) {
    try {
      const {
        profileObjectId,
        privateKey,
        iocHash,
        threatType,
        severity,
        confidenceScore,
        stixPattern,
        mitreTechniques,
        expirationHours,
        submissionFee
      } = req.body;

      // Validate required fields
      const requiredFields = [
        'profileObjectId', 'privateKey', 'iocHash', 'threatType', 
        'severity', 'confidenceScore', 'stixPattern'
      ];
      
      for (const field of requiredFields) {
        if (!req.body[field]) {
          return res.status(400).json({ 
            error: `${field} is required` 
          });
        }
      }

      const keypair = Ed25519Keypair.fromSecretKey(privateKey);
      const tx = new TransactionBlock();

      const [feeCoin] = tx.splitCoins(tx.gas, [
        tx.pure(submissionFee || '1000000') // Default 0.001 SUI
      ]);

      tx.moveCall({
        target: `${this.config.packageId}::threat_intelligence::submit_intelligence`,
        arguments: [
          tx.object(this.config.platformObjectId),
          tx.object(profileObjectId),
          tx.pure(Array.from(Buffer.from(iocHash, 'hex'))),
          tx.pure(threatType),
          tx.pure(severity),
          tx.pure(confidenceScore),
          tx.pure(stixPattern),
          tx.pure(mitreTechniques || []),
          tx.pure(expirationHours || 24),
          feeCoin,
          tx.object('0x6'), // Clock object
        ],
      });

      const result = await this.suiClient.signAndExecuteTransactionBlock({
        signer: keypair,
        transactionBlock: tx,
        options: { 
          showEffects: true, 
          showEvents: true,
          showObjectChanges: true
        }
      });

      if (result.effects?.status?.status === 'success') {
        const response = {
          success: true,
          transactionDigest: result.digest,
          submitter: keypair.getPublicKey().toSuiAddress(),
          threatType: threatType,
          severity: severity,
          timestamp: new Date().toISOString()
        };

        // Extract intelligence object ID
        const intelligenceObject = result.objectChanges?.find(
          change => change.type === 'created' && 
          change.objectType?.includes('ThreatIntelligence')
        );
        
        if (intelligenceObject) {
          response.intelligenceObjectId = intelligenceObject.objectId;
        }

        res.json(response);
      } else {
        throw new Error(result.effects?.status?.error || 'Submission failed');
      }
    } catch (error) {
      logger.error('Intelligence submission error:', error);
      res.status(500).json({ 
        error: 'Intelligence submission failed', 
        details: error.message 
      });
    }
  }

  async getIntelligence(req, res) {
    try {
      const { id } = req.params;
      
      // Check cache first
      const cacheKey = `intelligence:${id}`;
      const cached = await this.redisClient.get(cacheKey);
      
      if (cached) {
        return res.json(JSON.parse(cached));
      }

      const result = await this.suiClient.getObject({
        id: id,
        options: { showContent: true }
      });

      if (result.data?.content && 'fields' in result.data.content) {
        const fields = result.data.content.fields;
        const intelligence = {
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

        // Cache for 2 minutes
        await this.redisClient.setEx(cacheKey, 120, JSON.stringify(intelligence));
        
        res.json(intelligence);
      } else {
        res.status(404).json({ error: 'Intelligence not found' });
      }
    } catch (error) {
      logger.error('Error fetching intelligence:', error);
      res.status(500).json({ error: 'Failed to fetch intelligence' });
    }
  }

  async getRecentEvents(req, res) {
    try {
      const limit = parseInt(req.query.limit) || 50;
      const eventType = req.query.type;
      
      const cacheKey = `events:${eventType || 'all'}:${limit}`;
      const cached = await this.redisClient.get(cacheKey);
      
      if (cached) {
        return res.json(JSON.parse(cached));
      }

      const filter = { Package: this.config.packageId };
      if (eventType) {
        filter.EventType = eventType;
      }

      const events = await this.suiClient.queryEvents({
        query: filter,
        limit: limit,
        order: 'descending'
      });

      const processedEvents = events.data.map(event => ({
        type: event.type,
        timestamp: parseInt(event.timestampMs || '0'),
        data: event.parsedJson,
        transactionDigest: event.transactionDigest,
        id: event.id
      }));

      // Cache for 30 seconds
      await this.redisClient.setEx(cacheKey, 30, JSON.stringify(processedEvents));
      
      res.json(processedEvents);
    } catch (error) {
      logger.error('Error fetching events:', error);
      res.status(500).json({ error: 'Failed to fetch events' });
    }
  }

  async getThreatTrends(req, res) {
    try {
      const timeframe = parseInt(req.query.timeframe) || 24; // hours
      const cacheKey = `trends:${timeframe}`;
      const cached = await this.redisClient.get(cacheKey);
      
      if (cached) {
        return res.json(JSON.parse(cached));
      }

      // Get recent submission events
      const events = await this.suiClient.queryEvents({
        query: { Package: this.config.packageId },
        limit: 1000,
        order: 'descending'
      });

      const currentTime = Date.now();
      const cutoffTime = currentTime - (timeframe * 60 * 60 * 1000);

      const submissionEvents = events.data.filter(event => 
        event.type.includes('IntelligenceSubmitted') &&
        parseInt(event.timestampMs || '0') > cutoffTime
      );

      const threatTypes = {};
      const severityDistribution = {};
      const hourlySubmissions = {};

      submissionEvents.forEach(event => {
        const data = event.parsedJson;
        if (data) {
          // Count threat types
          threatTypes[data.threat_type] = (threatTypes[data.threat_type] || 0) + 1;
          
          // Count severity distribution
          if (data.severity) {
            severityDistribution[data.severity] = (severityDistribution[data.severity] || 0) + 1;
          }

          // Count hourly submissions
          const hour = Math.floor(parseInt(event.timestampMs) / (60 * 60 * 1000));
          hourlySubmissions[hour] = (hourlySubmissions[hour] || 0) + 1;
        }
      });

      const trends = {
        timeframe: `${timeframe} hours`,
        totalSubmissions: submissionEvents.length,
        threatTypes,
        severityDistribution,
        submissionTrend: Object.entries(hourlySubmissions)
          .map(([hour, count]) => ({
            time: parseInt(hour) * 60 * 60 * 1000,
            count,
          }))
          .sort((a, b) => a.time - b.time),
      };

      // Cache for 10 minutes
      await this.redisClient.setEx(cacheKey, 600, JSON.stringify(trends));
      
      res.json(trends);
    } catch (error) {
      logger.error('Error analyzing trends:', error);
      res.status(500).json({ error: 'Failed to analyze trends' });
    }
  }

  initializeErrorHandling() {
    // 404 handler
    this.app.use((req, res) => {
      res.status(404).json({ 
        error: 'Endpoint not found',
        path: req.path 
      });
    });

    // Global error handler
    this.app.use((error, req, res, next) => {
      logger.error('Unhandled error:', error);
      
      res.status(error.status || 500).json({
        error: error.message || 'Internal server error',
        ...(this.config.nodeEnv === 'development' && { stack: error.stack })
      });
    });
  }

  async start() {
    try {
      await this.initialize();
      
      const server = this.app.listen(this.config.port, () => {
        logger.info(`CTI API Server running on port ${this.config.port}`);
        logger.info(`Environment: ${this.config.nodeEnv}`);
        logger.info(`Sui Network: ${this.config.suiNetwork}`);
      });

      // Graceful shutdown
      process.on('SIGTERM', () => {
        logger.info('SIGTERM received, shutting down gracefully');
        server.close(() => {
          this.redisClient?.quit();
          process.exit(0);
        });
      });

      return server;
    } catch (error) {
      logger.error('Failed to start server:', error);
      process.exit(1);
    }
  }
}

// Start server if this file is run directly
if (require.main === module) {
  const server = new CTIAPIServer();
  server.start();
}

module.exports = CTIAPIServer;