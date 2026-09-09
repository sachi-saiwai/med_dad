import assert from 'node:assert/strict';
import test from 'node:test';

import {
  buildOpenAIJsonRequest,
  generateOpenAIJson,
  readOpenAIOutputText,
} from '../api/_lib/openai.js';

const simpleSchema = {
  type: 'object',
  additionalProperties: false,
  properties: { value: { type: 'string' } },
  required: ['value'],
};

test('OpenAI request uses stateless strict structured output', () => {
  const request = buildOpenAIJsonRequest({
    prompt: 'extract this',
    responseSchema: simpleSchema,
    schemaName: 'test_extraction',
    model: 'gpt-5.6-luna',
  });

  assert.equal(request.model, 'gpt-5.6-luna');
  assert.equal(request.store, false);
  assert.deepEqual(request.reasoning, { effort: 'none' });
  const text = request.text as {
    format: { type: string; name: string; strict: boolean; schema: unknown };
  };
  assert.equal(text.format.type, 'json_schema');
  assert.equal(text.format.name, 'test_extraction');
  assert.equal(text.format.strict, true);
  assert.deepEqual(text.format.schema, simpleSchema);
});

test('OpenAI image input is sent as an inline data URL', () => {
  const request = buildOpenAIJsonRequest({
    prompt: 'extract this image',
    responseSchema: simpleSchema,
    schemaName: 'image_extraction',
    model: 'gpt-5.6-luna',
    inlineData: { mimeType: 'image/jpeg', data: 'aW1hZ2U=' },
  });
  const input = request.input as Array<{
    content: Array<Record<string, unknown>>;
  }>;

  assert.deepEqual(input[0]?.content[1], {
    type: 'input_image',
    detail: 'high',
    image_url: 'data:image/jpeg;base64,aW1hZ2U=',
  });
});

test('OpenAI PDF input is sent as an inline file', () => {
  const request = buildOpenAIJsonRequest({
    prompt: 'extract this PDF',
    responseSchema: simpleSchema,
    schemaName: 'pdf_extraction',
    model: 'gpt-5.6-luna',
    inlineData: { mimeType: 'application/pdf', data: 'cGRm' },
  });
  const input = request.input as Array<{
    content: Array<Record<string, unknown>>;
  }>;

  assert.deepEqual(input[0]?.content[1], {
    type: 'input_file',
    filename: 'certificate.pdf',
    file_data: 'data:application/pdf;base64,cGRm',
    detail: 'high',
  });
});

test('OpenAI response text is read from Responses API output items', () => {
  const text = readOpenAIOutputText({
    status: 'completed',
    output: [{
      type: 'message',
      content: [{ type: 'output_text', text: '{"value":"ok"}' }],
    }],
  });

  assert.equal(text, '{"value":"ok"}');
});

test('OpenAI JSON generation calls the Responses API and parses its output', async () => {
  const originalKey = process.env.OPENAI_API_KEY;
  const originalModel = process.env.OPENAI_MODEL;
  const originalFetch = globalThis.fetch;
  let requestedUrl = '';
  let requestedAuthorization = '';
  let requestedBody: Record<string, unknown> = {};
  process.env.OPENAI_API_KEY = 'test-key';
  process.env.OPENAI_MODEL = 'gpt-5.6-luna';
  globalThis.fetch = (async (input, init) => {
    requestedUrl = String(input);
    requestedAuthorization = new Headers(init?.headers).get('authorization') || '';
    requestedBody = JSON.parse(String(init?.body)) as Record<string, unknown>;
    return new Response(JSON.stringify({
      status: 'completed',
      output: [{
        type: 'message',
        content: [{ type: 'output_text', text: '{"value":"ok"}' }],
      }],
    }), { status: 200, headers: { 'Content-Type': 'application/json' } });
  }) as typeof fetch;

  try {
    const result = await generateOpenAIJson<{ value: string }>({
      prompt: 'extract this',
      responseSchema: simpleSchema,
      schemaName: 'test_extraction',
    });

    assert.deepEqual(result, { data: { value: 'ok' }, model: 'gpt-5.6-luna' });
    assert.equal(requestedUrl, 'https://api.openai.com/v1/responses');
    assert.equal(requestedAuthorization, 'Bearer test-key');
    assert.equal(requestedBody.store, false);
  } finally {
    globalThis.fetch = originalFetch;
    if (originalKey === undefined) delete process.env.OPENAI_API_KEY;
    else process.env.OPENAI_API_KEY = originalKey;
    if (originalModel === undefined) delete process.env.OPENAI_MODEL;
    else process.env.OPENAI_MODEL = originalModel;
  }
});
