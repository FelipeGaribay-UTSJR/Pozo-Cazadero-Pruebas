// Serverless Function para alojarse en Vercel
// Ruta de acceso: /api/mercadopago

export default async function handler(req, res) {
  // CORS Configurations
  res.setHeader('Access-Control-Allow-Credentials', true);
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'OPTIONS,POST');
  res.setHeader(
    'Access-Control-Allow-Headers',
    'X-CSRF-Token, X-Requested-With, Accept, Accept-Version, Content-Length, Content-MD5, Content-Type, Date, X-Api-Version'
  );

  if (req.method === 'OPTIONS') {
    res.status(200).end();
    return;
  }

  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed. Use POST.' });
  }

  const { recibo_id, monto, titulo } = req.body;
  const ACCESS_TOKEN = process.env.MERCADOPAGO_ACCESS_TOKEN;

  if (!ACCESS_TOKEN) {
    return res.status(500).json({ error: 'Configuración de servidor incompleta (falta ACCESS_TOKEN).' });
  }

  if (!recibo_id || monto === undefined) {
    return res.status(400).json({ error: 'Faltan parámetros requeridos: recibo_id, monto.' });
  }

  try {
    const preferenceData = {
      items: [
        {
          id: recibo_id,
          title: titulo || `Pago de Recibo de Agua`,
          quantity: 1,
          currency_id: 'MXN',
          unit_price: Number(monto)
        }
      ],
      // URLs a las que el usuario regresará al acabar
      back_urls: {
        success: 'https://hydra-real.vercel.app/', // Cambiar por dominio si distinto
        failure: 'https://hydra-real.vercel.app/',
        pending: 'https://hydra-real.vercel.app/'
      },
      auto_return: 'approved',
      external_reference: recibo_id,
      statement_descriptor: "AGUA POTABLE",
    };

    // Petición directa a la API de Mercado Pago sin necesidad de instanciar el SDK (evita package.json)
    const response = await fetch('https://api.mercadopago.com/checkout/preferences', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${ACCESS_TOKEN}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(preferenceData)
    });

    const data = await response.json();

    if (!response.ok) {
        console.error("Error MP:", data);
        return res.status(400).json({ error: 'Error al generar preferencia en Mercado Pago', details: data });
    }

    // Retorna a Flutter el init_point para que pueda abrirlo
    return res.status(200).json({ 
        ok: true,
        init_point: data.init_point, 
        preference_id: data.id 
    });

  } catch (error) {
    console.error("Excepción en Vercel Function:", error);
    return res.status(500).json({ error: 'Error interno del servidor', message: error.message });
  }
}
