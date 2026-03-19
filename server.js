const express = require('express');
const swaggerUi = require('swagger-ui-express');
const YAML = require('yamljs');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 3000;

// Carregar o arquivo YAML do Swagger
const swaggerDocument = YAML.load(path.join(__dirname, 'controlid_swagger_full.yaml'));

// Rota raiz redirecionando para o Swagger
app.get('/', (req, res) => {
    res.redirect('/api-docs');
});

// Configurar o Swagger UI na rota /api-docs
app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerDocument));

app.listen(PORT, () => {
    console.log(`Servidor Swagger rodando na porta ${PORT}`);
    console.log(`Acesse: http://localhost:${PORT}/api-docs`);
});
