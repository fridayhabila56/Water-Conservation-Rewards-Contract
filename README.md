# 💧 Water Conservation Rewards Contract

A Clarity smart contract that incentivizes water conservation by rewarding users who stay under their water usage thresholds. Built on the Stacks blockchain with integrated oracle support for real-world water usage data.

## 🌟 Features

- **User Registration** 📝 - Users can register with their water usage thresholds
- **Oracle Integration** 🔗 - Authorized oracles report actual water usage data
- **Tiered Rewards** 🏆 - Different reward levels based on conservation performance
- **Period Management** 📅 - Configurable reward periods for ongoing tracking
- **Admin Controls** ⚙️ - Contract owner can manage settings and oracles

## 🚀 How It Works

1. **Register**: Users pay a registration fee and set their water usage threshold
2. **Monitor**: Authorized oracles report actual water usage for each period
3. **Reward**: Users who stay under their threshold can claim rewards
4. **Repeat**: New periods allow for continuous conservation incentives

## 💰 Reward Tiers

- **Super Saver** 🌟 - Use ≤50% of threshold = 2x base reward
- **Good Saver** ⭐ - Use ≤75% of threshold = 1.5x base reward  
- **Basic Saver** ✨ - Use ≤100% of threshold = 1x base reward

## 📋 Usage Instructions

### For Users

#### Register as a User
```clarity
(contract-call? .Water-Conservation-Rewards register-user u1000) ;; Set 1000 gallon threshold
```

#### Check Your Registration
```clarity
(contract-call? .Water-Conservation-Rewards get-user-info 'SP1234...)
```

#### Claim Your Reward
```clarity
(contract-call? .Water-Conservation-Rewards claim-reward)
```

#### Check Reward Eligibility
```clarity
(contract-call? .Water-Conservation-Rewards get-reward-eligibility 'SP1234...)
```

### For Oracles

#### Report Water Usage
```clarity
(contract-call? .Water-Conservation-Rewards report-usage 'SP1234... u850) ;; Report 850 gallons used
```

### For Contract Owner

#### Authorize an Oracle
```clarity
(contract-call? .Water-Conservation-Rewards authorize-oracle 'SP-ORACLE...)
```

#### Set Base Reward Amount
```clarity
(contract-call? .Water-Conservation-Rewards set-base-reward u200) ;; 200 STX base reward
```

#### Advance to Next Period
```clarity
(contract-call? .Water-Conservation-Rewards advance-period)
```

#### Fund the Contract
```clarity
(contract-call? .Water-Conservation-Rewards fund-contract)
```

## 🔧 Configuration

### Default Settings
- **Base Reward**: 100 STX
- **Registration Fee**: 10 STX
- **Period Duration**: 144 blocks (~24 hours)

### Admin Functions
- `set-base-reward` - Update reward amounts
- `set-registration-fee` - Update registration cost
- `authorize-oracle` / `revoke-oracle` - Manage oracle permissions
- `advance-period` - Move to next reward period
- `emergency-withdraw` - Emergency fund recovery

## 📊 Read-Only Functions

- `get-user-info` - Get user registration details
- `get-user-usage` - Get usage data for specific period
- `get-contract-info` - Get contract configuration
- `is-user-registered` - Check if user is registered
- `is-oracle-authorized` - Check oracle authorization
- `get-reward-eligibility` - Check reward eligibility and amount
- `get-period-stats` - Get statistics for a period

## 🛡️ Security Features

- **Owner-only functions** protected by access control
- **Oracle authorization** system prevents unauthorized data
- **Usage validation** ensures data integrity
- **Reward claiming** prevents double-claiming
- **Emergency controls** for contract management

## 🚧 Development

### Prerequisites
- Clarinet CLI
- Node.js
- Stacks Wallet

### Testing
```bash
clarinet test
```

### Deployment
```bash
clarinet deploy
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

## 📄 License

This project is open source and available under the MIT License.

## 🌍 Environmental Impact

By incentivizing water conservation through blockchain technology, this contract promotes sustainable water usage patterns and rewards environmentally conscious behavior. Every gallon saved counts! 🌱
