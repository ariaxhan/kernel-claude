export interface Learning {
  id: string;
  ts: string;
  type: 'failure' | 'pattern' | 'gotcha' | 'preference';
  insight: string;
  evidence: string;
  domain: string;
  hit_count: number;
  last_hit: string;
}

export interface ContextEntry {
  id: string;
  ts: string;
  type: 'contract' | 'checkpoint' | 'handoff' | 'verdict';
  contract_id: string;
  agent: string;
  content: string;
}

export interface ErrorEntry {
  id: string;
  ts: string;
  tool: string;
  error: string;
  file: string;
  context: string;
}

export interface SessionEntry {
  id: string;
  started_at: string;
  ended_at: string;
  task_type: string;
  tier: number;
  nodes_loaded: string;
  tokens_used: number;
  success: number;
  outcome: string;
}

export interface SystemHealth {
  learnings: { total: number; patterns: number; failures: number; gotchas: number };
  errors: { total: number; recent: number };
  sessions: { total: number; recent: number; successRate: number };
  lastCheckpoint: string | null;
  agents: { total: number };
}

export interface FileNode {
  name: string;
  path: string;
  type: 'file' | 'directory';
  children?: FileNode[];
}
