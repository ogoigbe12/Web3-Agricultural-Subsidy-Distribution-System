# 🌾 Web3 Agricultural Subsidy Distribution System

A decentralized smart contract system built on Stacks blockchain that enables transparent and corruption-free distribution of government agricultural subsidies directly to verified farmers.

## 🚀 Features

- **👨‍🌾 Farmer Registration**: Secure farmer onboarding with verification system
- **📊 Yield Data Management**: Submit and verify crop yield data
- **🌡️ IoT Sensor Integration**: Real-time environmental data collection
- **💰 Direct Subsidy Distribution**: Automated payments based on verified yields
- **🔍 Transparency**: All transactions recorded on blockchain
- **🛡️ Anti-Corruption**: Eliminates middlemen and ensures direct payments

## 📋 Contract Functions

### Public Functions

| Function | Description | Access |
|----------|-------------|---------|
| `register-farmer` | Register as a new farmer | Anyone |
| `verify-farmer` | Verify farmer eligibility | Owner only |
| `add-funds` | Add funds to contract | Anyone |
| `submit-yield-data` | Submit crop yield information | Verified farmers |
| `verify-yield-data` | Verify submitted yield data | Owner only |
| `register-sensor` | Register IoT sensor for farm | Owner only |
| `update-sensor-data` | Update sensor readings | Owner only |
| `claim-subsidy` | Claim calculated subsidy | Verified farmers |

### Read-Only Functions

| Function | Description |
|----------|-------------|
| `get-farmer-info` | Get farmer details |
| `get-yield-data` | Get yield information |
| `get-sensor-data` | Get sensor readings |
| `get-subsidy-claim` | Get claim status |
| `get-contract-balance` | Get available funds |
| `is-farmer-verified` | Check verification status |

## 🛠️ Setup & Deployment

### Prerequisites
- Clarinet CLI installed
- Stacks wallet configured

### Installation

```bash
git clone <repository-url>
cd web3-agricultural-subsidy
clarinet check
