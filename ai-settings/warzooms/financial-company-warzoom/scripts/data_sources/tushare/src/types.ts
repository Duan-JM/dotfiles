export type QueryStatus =
  | "ok"
  | "no_data"
  | "authentication_failed"
  | "permission_denied"
  | "rate_limited"
  | "network_error"
  | "invalid_request"
  | "parse_error"
  | "ambiguous_data";

export type TushareScalar = string | number | boolean | null;

export interface TushareRequest {
  api_name: string;
  params: Record<string, TushareScalar>;
  fields: string;
}

export interface TushareRawResponse {
  code: number;
  msg: string | null;
  data?: {
    fields?: unknown;
    items?: unknown;
  };
}

export interface QueryTask {
  id: string;
  apiName: string;
  params: Record<string, TushareScalar>;
  fields: string;
  sourceUrl: string;
  cardinality: "one" | "many";
}

export interface QueryExecution {
  task: QueryTask;
  status: QueryStatus;
  message: string | null;
  records: Array<Record<string, TushareScalar>>;
  rawResponse: TushareRawResponse | null;
  attempts: number;
}

export interface NormalizedQueryResult {
  schema_version: 1;
  source: "tushare";
  request: {
    query_type: string;
    company_id: string;
    params: Record<string, TushareScalar>;
    fields: string[];
  };
  retrieved_at: string;
  source_url: string;
  source_tier: "secondary";
  data_semantics: {
    currency: "CNY";
    unit_policy: "field_specific";
    accounting_basis: "provider_reported";
    period: string | null;
  };
  response_sha256: string | null;
  status: QueryStatus;
  message: string | null;
  attempts: number;
  records: Array<Record<string, TushareScalar>>;
}

export interface StoredArtifacts {
  rawPath: string | null;
  normalizedPath: string;
}
