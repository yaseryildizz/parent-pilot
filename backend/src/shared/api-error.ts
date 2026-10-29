export type FieldIssue = {
  field: string;
  message: string;
};

export class ApiError extends Error {
  readonly statusCode: number;
  readonly code: string;
  readonly retryable: boolean;
  readonly fieldIssues?: FieldIssue[] | undefined;

  constructor(options: {
    statusCode: number;
    code: string;
    message: string;
    retryable?: boolean;
    fieldIssues?: FieldIssue[];
  }) {
    super(options.message);
    this.statusCode = options.statusCode;
    this.code = options.code;
    this.retryable = options.retryable ?? false;
    this.fieldIssues = options.fieldIssues;
  }
}

export function errorEnvelope(error: ApiError, requestID: string): {
  error: {
    code: string;
    message: string;
    requestID: string;
    retryable: boolean;
    fieldIssues?: FieldIssue[];
  };
} {
  const envelope: {
    error: {
      code: string;
      message: string;
      requestID: string;
      retryable: boolean;
      fieldIssues?: FieldIssue[];
    };
  } = {
    error: {
      code: error.code,
      message: error.message,
      requestID,
      retryable: error.retryable
    }
  };
  if (error.fieldIssues) envelope.error.fieldIssues = error.fieldIssues;
  return envelope;
}
