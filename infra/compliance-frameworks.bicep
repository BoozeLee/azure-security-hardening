// Enterprise Compliance Frameworks
// Implements industry-standard compliance frameworks for enterprise organizations

targetScope = 'subscription'

@description('Enable ISO 27001 compliance framework')
param enableISO27001 bool = true

@description('Enable SOC 2 compliance framework')
param enableSOC2 bool = true

@description('Enable HIPAA compliance framework')
param enableHIPAA bool = true

@description('Enable PCI DSS compliance framework')
param enablePCIDSS bool = true

@description('Enable NIST compliance framework')
param enableNIST bool = true

// ISO 27001:2013 Compliance
resource iso27001Assignment 'Microsoft.Authorization/policyAssignments@2022-06-01' = if (enableISO27001) {
  name: 'iso27001-compliance'
  properties: {
    displayName: 'ISO 27001:2013 Compliance'
    description: 'Implements ISO 27001:2013 information security management controls'
    policyDefinitionId: '/providers/Microsoft.Authorization/policySetDefinitions/89c6cddc-1c73-4ac1-b19c-54d1a15a42f2'
    enforcementMode: 'Default'
    metadata: {
      category: 'Compliance'
      framework: 'ISO27001'
      version: '2013'
    }
    nonComplianceMessages: [
      {
        message: 'Resource does not meet ISO 27001:2013 compliance requirements'
      }
    ]
  }
}

// SOC 2 Type 2 Compliance
resource soc2Assignment 'Microsoft.Authorization/policyAssignments@2022-06-01' = if (enableSOC2) {
  name: 'soc2-compliance'
  properties: {
    displayName: 'SOC 2 Type 2 Compliance'
    description: 'Implements SOC 2 Trust Service Criteria controls'
    policyDefinitionId: '/providers/Microsoft.Authorization/policySetDefinitions/a169a624-5599-4385-a696-c8d643089fab'
    enforcementMode: 'Default'
    metadata: {
      category: 'Compliance'
      framework: 'SOC2'
      type: 'Type2'
    }
    nonComplianceMessages: [
      {
        message: 'Resource does not meet SOC 2 Type 2 compliance requirements'
      }
    ]
  }
}

// HIPAA/HITRUST Compliance
resource hipaaAssignment 'Microsoft.Authorization/policyAssignments@2022-06-01' = if (enableHIPAA) {
  name: 'hipaa-compliance'
  properties: {
    displayName: 'HIPAA HITRUST 9.2 Compliance'
    description: 'Implements HIPAA/HITRUST controls for healthcare data protection'
    policyDefinitionId: '/providers/Microsoft.Authorization/policySetDefinitions/a169a624-5599-4385-a696-c8d643089fab'
    enforcementMode: 'Default'
    metadata: {
      category: 'Compliance'
      framework: 'HIPAA'
      version: '9.2'
    }
    nonComplianceMessages: [
      {
        message: 'Resource does not meet HIPAA/HITRUST compliance requirements'
      }
    ]
  }
}

// PCI DSS 3.2.1 Compliance
resource pciDssAssignment 'Microsoft.Authorization/policyAssignments@2022-06-01' = if (enablePCIDSS) {
  name: 'pci-dss-compliance'
  properties: {
    displayName: 'PCI DSS 3.2.1 Compliance'
    description: 'Implements PCI DSS controls for payment card data protection'
    policyDefinitionId: '/providers/Microsoft.Authorization/policySetDefinitions/496eeda9-8f2f-4d5e-8dfd-204f0a92ed41'
    enforcementMode: 'Default'
    metadata: {
      category: 'Compliance'
      framework: 'PCIDSS'
      version: '3.2.1'
    }
    nonComplianceMessages: [
      {
        message: 'Resource does not meet PCI DSS 3.2.1 compliance requirements'
      }
    ]
  }
}

// NIST SP 800-53 Rev. 5 Compliance
resource nistAssignment 'Microsoft.Authorization/policyAssignments@2022-06-01' = if (enableNIST) {
  name: 'nist-compliance'
  properties: {
    displayName: 'NIST SP 800-53 Rev. 5 Compliance'
    description: 'Implements NIST cybersecurity framework controls'
    policyDefinitionId: '/providers/Microsoft.Authorization/policySetDefinitions/cf25b9c1-bd23-4eb6-bd2c-f4f3ac644a5f'
    enforcementMode: 'Default'
    metadata: {
      category: 'Compliance'
      framework: 'NIST'
      version: 'SP800-53-Rev5'
    }
    nonComplianceMessages: [
      {
        message: 'Resource does not meet NIST SP 800-53 Rev. 5 compliance requirements'
      }
    ]
  }
}

// Outputs
output iso27001AssignmentId string = enableISO27001 ? iso27001Assignment.id : ''
output soc2AssignmentId string = enableSOC2 ? soc2Assignment.id : ''
output hipaaAssignmentId string = enableHIPAA ? hipaaAssignment.id : ''
output pciDssAssignmentId string = enablePCIDSS ? pciDssAssignment.id : ''
output nistAssignmentId string = enableNIST ? nistAssignment.id : ''
