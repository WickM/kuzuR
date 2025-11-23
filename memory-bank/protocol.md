# Memory Bank Protocol

This document outlines the robust, multi-stage consolidation process for updating the Memory Bank. This protocol replaces simple overwrites with a structured, append-only logging and validation system to prevent context loss and ensure strategic integrity.

---

### Core Principles

1.  **Preserve History:** Never overwrite. All updates to `activeContext.md` and `progress.md` are appended, creating a chronological log.
2.  **Explicit Triggers:** Memory consolidation is a deliberate, verifiable action, not a subjective judgment call.
3.  **Validate Learning:** Strategic lessons are peer-reviewed before being integrated into the core `reasoning_bank.md`, preventing the pollution of core strategy.

---

### The Updated Consolidation Workflow

```mermaid
flowchart TD
    subgraph Execution Phase
        direction LR
        A[Action/Task Step] --> B{Consolidation Trigger Met?}
    end

    subgraph Consolidation Phase
        direction TB
        C[Propose Memory Update in Chat] --> D{User Approval}
        D -->|Yes| E[Append Update to activeContext/progress]
        E --> F{New Strategic Lesson Identified?}
        F -->|Yes| G[Draft [PROPOSED REASONING UNIT] in activeContext.md]
        F -->|No| H[End Consolidation]
        G --> H
    end
    
    subgraph Validation Phase
        direction TB
        I[User Command: "validate reasoning units"] --> J[Review Proposed Units in activeContext.md]
        J --> K{Unit Approved?}
        K -->|Yes| L[Archive from activeContext & Add to reasoning_bank.md]
        K -->|No| M[Discard or Refine Unit]
        L --> N[End Validation]
        M --> N
    end

    A --> B
    B -->|Yes| C
    B -->|No| A
```

---

### Instructions for Memory Update & Consolidation

1.  **Consolidation Triggers (Replaces "Significant Action"):** I must initiate the memory consolidation process upon the completion of any of the following:
    *   A primary task or sub-task from an established plan (`task_progress` checklist).
    *   Before switching from `ACT` mode back to `PLAN` mode.
    *   After a critical failure or unexpected discovery that invalidates the current plan.
    *   When explicitly commanded by the user (`"update memory bank"`).

2.  **Append-Only State Logging (Replaces "Update"):**
    *   When a trigger is met, I will first propose the memory update in chat for your review.
    *   Upon approval, I will append a new, timestamped entry to `activeContext.md` and `progress.md`. This entry will detail the work completed, the outcome, and the new state of the project.
    *   This ensures a full, auditable history of the session is preserved.

3.  **Staged Reasoning Bank Update (Replaces Direct Addition):**
    *   If the self-critique process identifies a new, generalizable strategic lesson, I will **not** add it directly to `reasoning_bank.md`.
    *   Instead, I will draft the lesson within `activeContext.md` under a clear heading: `[PROPOSED REASONING UNIT]`.
    *   This unit will remain in `activeContext.md` as a proposal until you explicitly validate it.
    *   **Validation:** You can trigger a review of all proposed units. Upon your approval for a specific unit, I will formally add it to `reasoning_bank.md` and remove the proposal from `activeContext.md`. This acts as a quality gate for my strategic learning.
