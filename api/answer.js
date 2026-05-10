export default async function handler(req, res) {
  // CORS headers
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  const { question } = req.body;

  if (!question || question.trim().length === 0) {
    return res.status(400).json({ error: 'Question is required' });
  }

  const apiKey = process.env.OPENROUTER_API_KEY;

  if (!apiKey) {
    return res.status(500).json({ error: 'API key not configured' });
  }

  try {
    const response = await fetch('https://openrouter.ai/api/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ' + apiKey,
        'HTTP-Referer': 'https://arcinfogent.xyz',
        'X-Title': 'ArcInfoAgent'
      },
      body: JSON.stringify({
        model: 'google/gemini-2.0-flash-001',
        messages: [
          {
            role: 'system',
            content: 'You are ArcInfoAgent, an AI assistant that answers questions about Arc Network. Arc Network is a blockchain platform that uses USDC as native gas token, supports ERC-8004 for AI agent registration, and provides fast block times for DeFi and AI agent applications. Keep answers concise (2-4 sentences), accurate, and helpful. If the question is not about Arc Network or blockchain, still give a helpful answer but mention that ArcInfoAgent specializes in Arc Network topics.'
          },
          {
            role: 'user',
            content: question
          }
        ],
        max_tokens: 300,
        temperature: 0.7
      })
    });

    if (!response.ok) {
      const errData = await response.json().catch(() => ({}));
      throw new Error(errData.error?.message || 'AI API error');
    }

    const data = await response.json();
    const answer = data.choices[0].message.content;

    return res.status(200).json({ answer });

  } catch (e) {
    return res.status(500).json({ error: 'AI error: ' + e.message });
  }
}
