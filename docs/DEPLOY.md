# Deploy TabGis

Este documento e a referencia principal de deploy para ambiente TabGis moderno.

## Ambiente padrao
- Orquestracao: `infra/docker-compose.yml`
- Frontend/proxy: `http://<host>:8088/`
- GeoServer: `http://<host>:8080/geoserver/web`
- TileServer: `http://<host>:8081/`

## Sequencia recomendada
1. Subir stack:
   - `docker compose -f infra/docker-compose.yml up -d`
2. Verificar containers:
   - `docker ps --format "table {{.Names}}\t{{.Status}}"`
3. Validar frontend:
   - abrir `http://<host>:8088/`

## 2. Banco e scripts SQL

Executar scripts versionados em `infra/sql/` na ordem indicada em `docs/CONTEXT_STATE.md` (tabela *Scripts versionados*) ou, para o passo-a-passo alargado, em `docs/DEPLOY_POC.md` (secção 2).

## Diagnostico rapido
- Preferir acesso via `:8088` para garantir same-origin (`/geoserver`, `/tiles`, `/api`).
- Em caso de recreacao do TileServer, reiniciar `web` para re-resolver DNS interno Docker.

## Referencias complementares
- `docs/CONTEXT_STATE.md`
- `docs/DEPLOY_POC.md` (legado com detalhes historicos e troubleshooting estendido)
