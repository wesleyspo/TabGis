# TabGis - Plano de Execucao Autonoma (10h)

## Objetivo
Executar uma iteracao completa sem intervencao humana, elevando TabGis para uma base mais profissional, com cobertura funcional das abas operacionais e ganho de confiabilidade tecnica.

## Escopo fechado desta janela
- Reestruturacao orientada a manutencao humana (documentacao e trilhas de operacao).
- Reforco de testes automatizados (E2E para navegacao principal e abas operacionais).
- Atualizacao de documentacao para linguagem de produto TabGis (sem dependencia de terminologia de POC).
- Consolidacao do backlog das frentes OMS, MWM, DMS, IND, SMT, TMP (Clima), AUD, Esquematico e Configuracoes.

## Ondas de execucao
### Onda 1 - Baseline e qualidade
- Validar stack e testes existentes.
- Ampliar suite E2E para cobertura de:
  - abertura de Operacao;
  - todas as abas (OMS, MWM, DMS, IND, SMT, TMP, AUD);
  - Configuracoes (visualizacao, utilizadores, tipos de dominio, traducoes, ajuda);
  - atalho de Clima (TMP).
- Aceite: testes de fumo executam sem regressao critica.

### Onda 2 - Documentacao profissional
- Publicar nomenclatura principal TabGis em guias de operador.
- Acrescentar runbook executivo de "proximos 10h" com prioridades.
- Aceite: documentacao orienta onboarding tecnico sem ambiguidade de termos.

### Onda 3 - Frentes funcionais por modulo
- OMS: consolidar fluxo grade -> folha -> tarefas.
- MWM: manter foco em equipes e rotas demo com capacidade de expansao.
- TMP: fluxo de previsao e radar com feedback operacional.
- AUD: manter trilha de arquivo pre-delete e superficie de consulta.
- Configuracoes: manter governanca por modal (idioma, visualizacao, users, ref, traducoes).
- Esquematico: manter requisito de ligacao obrigatoria "Ir para o Mapa" no backlog tecnico.
- Aceite: backlog operacional priorizado, com fronteiras claras por modulo.

## Criterios de aceite da janela
- UI com comportamento de tela preservado (full, split 50/50 e foco no centro de controle).
- Nenhuma quebra em navegacao de abas e atalhos principais.
- Documentacao principal alinhada com linguagem de produto TabGis.
- Evidencia de validacao automatizada (E2E).

## Riscos e mitigacoes
- Dependencia de servicos externos (clima/radar): manter mensagens de fallback e estado.
- Mudancas em textos i18n: validar elementos por seletor estavel nos testes.
- Diferencas de ambiente: executar sempre via nginx `:8088` para same-origin.

## Entregaveis esperados ao fim da janela
- Testes E2E atualizados.
- Ajuda do operador atualizada.
- Documentos de escopo/deploy com nomes profissionais.
- Estado de contexto atualizado com o que foi efetivamente executado.
