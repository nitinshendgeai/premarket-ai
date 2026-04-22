exports.handler = async function(event, context) {
  try {
    const response = await fetch(
      'https://premarket-assistant-production.up.railway.app/premarket-analysis',
      { headers: { 'Accept': 'application/json' } }
    );
    const data = await response.json();
    return {
      statusCode: 200,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
      },
      body: JSON.stringify(data),
    };
  } catch (err) {
    return {
      statusCode: 500,
      body: JSON.stringify({ error: err.message }),
    };
  }
};
