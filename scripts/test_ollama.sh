#!/bin/bash

# Test script for Ollama connectivity
echo "Testing Ollama connectivity..."

OLLAMA_URL=${OLLAMA_URL:-"http://localhost:11434"}
MODEL_NAME=${OLLAMA_MODEL_VIBE_LEVEL:-"llama2"}

echo "Using Ollama URL: $OLLAMA_URL"
echo "Using Model: $MODEL_NAME"

# Test 1: Check if Ollama is running
echo "1. Checking if Ollama is accessible..."
if curl -s "$OLLAMA_URL/api/version" > /dev/null; then
    echo "✅ Ollama is accessible"
else
    echo "❌ Ollama is not accessible at $OLLAMA_URL"
    exit 1
fi

# Test 2: Check if model is available
echo "2. Checking if model '$MODEL_NAME' is available..."
if curl -s "$OLLAMA_URL/api/show" -d "{\"name\":\"$MODEL_NAME\"}" | grep -q "model"; then
    echo "✅ Model '$MODEL_NAME' is available"
else
    echo "❌ Model '$MODEL_NAME' is not available"
    echo "Run: ollama pull $MODEL_NAME"
    exit 1
fi

# Test 3: Simple generation test
echo "3. Testing simple generation..."
RESPONSE=$(curl -s "$OLLAMA_URL/api/generate" \
    -H "Content-Type: application/json" \
    -d "{\"model\":\"$MODEL_NAME\",\"prompt\":\"def hello():\",\"stream\":false}")

if echo "$RESPONSE" | grep -q "response"; then
    echo "✅ Generation test successful"
else
    echo "❌ Generation test failed"
    echo "Response: $RESPONSE"
    exit 1
fi

echo "🎉 All tests passed! Ollama is ready for vibe-level.nvim"
