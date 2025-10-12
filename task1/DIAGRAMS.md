# Визуальные диаграммы (Mermaid)

## 1. Архитектура решения

```mermaid
graph TB
    subgraph AWS["AWS Account: 651706749822"]
        subgraph IAM["IAM Service"]
            Role["IAM Role<br/>cmtr-4n6e9j62-iam-peld-iam_role"]
            Policy1["Identity-Based Policy<br/>AmazonS3FullAccess"]
            Role -->|attached| Policy1
        end
        
        subgraph S3["Amazon S3"]
            Bucket["S3 Bucket<br/>cmtr-4n6e9j62-iam-peld-bucket-2911738"]
            BucketPolicy["Resource-Based Policy<br/>Deny DeleteObject"]
            Bucket -->|has| BucketPolicy
        end
        
        Role -->|"tries to:<br/>GetObject ✅<br/>PutObject ✅<br/>DeleteObject ❌"| Bucket
    end
    
    style Policy1 fill:#90EE90
    style BucketPolicy fill:#FFB6C1
    style Role fill:#87CEEB
    style Bucket fill:#FFD700
```

## 2. Policy Evaluation Flow

```mermaid
flowchart TD
    Start([Request: s3:DeleteObject]) --> Default[Default: DENY]
    Default --> CheckDeny{Explicit DENY<br/>exists?}
    CheckDeny -->|YES| DenyResult[❌ DENY<br/>Access Denied]
    CheckDeny -->|NO| CheckAllow{ALLOW<br/>exists?}
    CheckAllow -->|YES| AllowResult[✅ ALLOW<br/>Access Granted]
    CheckAllow -->|NO| ImplicitDeny[❌ DENY<br/>Implicit Deny]
    
    style DenyResult fill:#ff6b6b
    style AllowResult fill:#51cf66
    style ImplicitDeny fill:#ff8787
    style Start fill:#339af0
```

## 3. Последовательность выполнения задачи

```mermaid
sequenceDiagram
    participant User
    participant IAM
    participant Role as IAM Role
    participant S3 as S3 Bucket
    
    Note over User,S3: Move 1: Attach Managed Policy
    User->>IAM: attach-role-policy
    IAM->>Role: AmazonS3FullAccess
    Role-->>User: ✅ Policy attached
    
    Note over User,S3: Move 2: Update Bucket Policy
    User->>S3: put-bucket-policy
    S3->>S3: Add Deny DeleteObject
    S3-->>User: ✅ Policy updated
    
    Note over User,S3: Verification
    User->>IAM: simulate-principal-policy
    IAM->>Role: Check permissions
    Role->>S3: Evaluate policies
    S3-->>IAM: Explicit DENY
    IAM-->>User: ❌ DeleteObject: DENIED
```

## 4. Матрица разрешений

```mermaid
graph LR
    subgraph Actions["S3 Actions"]
        A1[GetObject]
        A2[PutObject]
        A3[ListBucket]
        A4[DeleteObject]
    end
    
    subgraph Identity["Identity Policy<br/>AmazonS3FullAccess"]
        I1[ALLOW ✅]
        I2[ALLOW ✅]
        I3[ALLOW ✅]
        I4[ALLOW ✅]
    end
    
    subgraph Resource["Bucket Policy"]
        R1[- ]
        R2[- ]
        R3[- ]
        R4[DENY ❌]
    end
    
    subgraph Result["Final Result"]
        F1[ALLOW ✅]
        F2[ALLOW ✅]
        F3[ALLOW ✅]
        F4[DENY ❌]
    end
    
    A1 --> I1 --> R1 --> F1
    A2 --> I2 --> R2 --> F2
    A3 --> I3 --> R3 --> F3
    A4 --> I4 --> R4 --> F4
    
    style I1 fill:#90EE90
    style I2 fill:#90EE90
    style I3 fill:#90EE90
    style I4 fill:#90EE90
    style R4 fill:#FFB6C1
    style F1 fill:#51cf66
    style F2 fill:#51cf66
    style F3 fill:#51cf66
    style F4 fill:#ff6b6b
```

## 5. Взаимодействие компонентов

```mermaid
graph TB
    subgraph User["User/Application"]
        U[Makes Request]
    end
    
    subgraph Evaluation["AWS Policy Evaluation"]
        E1[Step 1: Check Explicit Deny]
        E2[Step 2: Check Organization SCPs]
        E3[Step 3: Check Resource Policies]
        E4[Step 4: Check Identity Policies]
        E5[Step 5: Check Permission Boundaries]
        E6[Step 6: Check Session Policies]
    end
    
    subgraph Policies["Policies in Task"]
        P1[Identity Policy:<br/>AmazonS3FullAccess<br/>ALLOW s3:*]
        P2[Resource Policy:<br/>Bucket Policy<br/>DENY DeleteObject]
    end
    
    subgraph Decision["Decision"]
        D{Result}
        D1[✅ ALLOW]
        D2[❌ DENY]
    end
    
    U --> E1
    E1 --> E2
    E2 --> E3
    E3 --> E4
    E4 --> E5
    E5 --> E6
    E6 --> D
    
    P2 -.->|affects| E3
    P1 -.->|affects| E4
    
    D -->|No Explicit Deny<br/>+ Has Allow| D1
    D -->|Explicit Deny| D2
    
    style P1 fill:#90EE90
    style P2 fill:#FFB6C1
    style D1 fill:#51cf66
    style D2 fill:#ff6b6b
    style E1 fill:#ffd43b
```

## 6. Сравнение до и после

```mermaid
graph LR
    subgraph Before["До применения политик"]
        B1[IAM Role]
        B2[No Permissions ❌]
        B1 --> B2
    end
    
    subgraph After["После Move 1"]
        A1[IAM Role]
        A2[AmazonS3FullAccess ✅]
        A3[Can Delete Objects ⚠️]
        A1 --> A2
        A2 --> A3
    end
    
    subgraph Final["После Move 2"]
        F1[IAM Role]
        F2[AmazonS3FullAccess ✅]
        F3[Bucket Policy Deny ❌]
        F4[Cannot Delete Objects ✅]
        F1 --> F2
        F1 --> F3
        F2 --> F4
        F3 --> F4
    end
    
    Before ==>|Move 1:<br/>attach-role-policy| After
    After ==>|Move 2:<br/>put-bucket-policy| Final
    
    style B2 fill:#ff6b6b
    style A2 fill:#51cf66
    style A3 fill:#ffd43b
    style F2 fill:#51cf66
    style F3 fill:#FFB6C1
    style F4 fill:#51cf66
```

## Как использовать эти диаграммы

### В GitHub / GitLab
Эти диаграммы Mermaid автоматически рендерятся в README файлах.

### В VS Code
Установите расширение "Markdown Preview Mermaid Support"

### Онлайн
Скопируйте код и вставьте на https://mermaid.live/

### В документации
Большинство современных систем документации (GitBook, Docusaurus, etc.) поддерживают Mermaid.

## Экспорт в изображения

```bash
# Установите Mermaid CLI
npm install -g @mermaid-js/mermaid-cli

# Конвертируйте в PNG
mmdc -i DIAGRAMS.md -o diagram.png

# Или в SVG
mmdc -i DIAGRAMS.md -o diagram.svg
```
