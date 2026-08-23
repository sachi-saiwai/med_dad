export interface ApiRequest {
  method?: string;
  query: Record<string, string | string[] | undefined>;
  headers: Record<string, string | string[] | undefined>;
  body?: unknown;
}

export interface ApiResponse {
  setHeader(name: string, value: string | number | readonly string[]): this;
  status(code: number): this;
  json(value: unknown): this;
  end(): this;
}
