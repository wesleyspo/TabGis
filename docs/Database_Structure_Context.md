# Modelo de dados TabGis — Utilities (referência técnica)

> **Diagramas (fluxos + ER):** abra no navegador o ficheiro [`Database_Structure_Context.html`](./Database_Structure_Context.html) (Mermaid, tema escuro).

> **Idioma dos artefactos:** nomes de tabelas, colunas, tipos e comentários SQL em **inglês (US)**; esta especificação narrativa está em **português**.  
> **Motor alvo:** **PostgreSQL 15+** com **PostGIS** para geometrias; não se assume sintaxe Oracle (`NUMBER`, `VARCHAR2`, `ENABLE`).

---

## 1. Objectivo e âmbito

Sistema de pós-graduação orientado ao mercado de **utilities**, com ferramentas **geográficas** e **tabulares**. O modelo cobre inicialmente **energia eléctrica**, mas deve permanecer **agnóstico** para extensão a **gás, água e esgoto, telecomunicações** (tipos e domínios parametrizados, não hard-coded apenas para electricidade).

**Fluxo operacional central (OMS):** chamadas (*calls*) geram ou associam-se a **ordens** (*work orders*); ordens ligam-se a **tarefas** (*tasks*), **equipas** (*crews*), **equipamentos** (*equipments*) e **eventos de rede** (*network events*). O domínio **MWM** (mobile workforce) gere equipes, turnos, deslocamentos e trajectos em tempo quase real.

---

## 2. Princípios de modelagem

| Princípio | Descrição |
|-----------|-----------|
| **Multi-utilitário** | Códigos de domínio (`utility_type`: electric, gas, water, sewer, telecom) em entidades relevantes ou via organização; *lookups* (`*_type_id`, `*_status_id`) partilháveis entre domínios quando o significado for idêntico. |
| **Rastreio por evento** | Toda entidade de negócio mutável possui referência a um **evento de alteração** (`event_id` → tabela canónica de eventos) para encadeamento temporal e auditoria de UI. |
| **Tipos auditáveis** | Onde o rascunho original indica **TYPE** genérico, prevê-se **tabela de domínio** (ex.: `ref.equipment_type`, `ref.order_type`) com versão/validade se necessário, e registo de alterações via `event_id` + histórico. |
| **Auditoria por domínio** | Para além de `event_id`, tabelas **analógicas de auditoria** (append-only) ou **JSONB archive** antes de `DELETE` (padrão já adoptado em `audit.operations_row_archive` para `operations.*`). |
| **Georreferenciação** | Preferir `geometry(Point, 4326)` ou `geography` em PostGIS em vez de pares `LAT`/`LONG` soltos; manter `location_description` para texto livre quando a feição ainda não estiver amarrada. |
| **Campos calculados** | Métricas derivadas (CHI, ETR, prioridade, *flags* de IA sobre texto de chamadas) podem ser **colunas materializadas**, **vistas** ou **tabelas de agregação** refrescadas por job — evitar duplicar lógica crítica só em colunas sem documentação da fórmula. |

---

## 3. Organização de schemas (alvo)

| Schema | Função |
|--------|--------|
| `landbase` | Dados geográficos de apoio (já existente: divisões, vias, recortes). |
| `config` | Parâmetros, traduções, idiomas (já existente). |
| `security` | Utilizadores e perfis (já existente). |
| `audit` | Históricos, *login*, arquivo pré-`DELETE` (já existente; extensível por domínio). |
| `ref` *(proposto)* | *Lookups* estáveis: tipos de equipamento, níveis de rede, estados de ligação, canais de chamada, tipos de contrato, etc. |
| `customer` *(proposto)* | Contratos, titulares, localizações de serviço. |
| `asset` ou `network` *(proposto)* | Equipamentos e relações hierárquicas na rede. |
| `oms` *(proposto)* | Chamadas, *feedbacks*, ordens, tarefas, eventos de rede, interrupções ao cliente. |
| `operations` | **POC actual:** `team`, `work_order`, `team_order_displacement`, `team_route` — subconjunto mínimo alinhado ao painel Operação até migração para o modelo completo `oms`/`mwm`. |

---

## 4. Domínio — Clientes (`customer.*`)

Representa o ponto de entrega / titular contratual ligado à rede.

### 4.1 Entidade: `customer.service_account` (proposta)

| Coluna (EN) | Tipo PostgreSQL sugerido | Obrig. | Notas |
|-------------|--------------------------|--------|--------|
| `id` | `BIGSERIAL` | PK | |
| `event_id` | `BIGINT` | FK → `audit.domain_event` ou equivalente | Toda alteração rastreada. |
| `account_number` | `VARCHAR(30)` | UQ | Identificador comercial. |
| `status_id` | `SMALLINT` | FK `ref.account_status` | Cadastro activo, suspenso, cortado, etc. |
| `customer_type_id` | `SMALLINT` | FK `ref.customer_type` | Residencial, comercial, industrial… |
| `equipment_id` | `VARCHAR(30)` | FK lógico → `network.equipment` | Ponto de rede servido. |
| `parent_equipment_id` | `VARCHAR(30)` | FK lógico | Equipamento “pai” na alimentação. |
| `last_name` | `VARCHAR(64)` | | |
| `first_name` | `VARCHAR(64)` | | |
| `email` | `VARCHAR(255)` | | |
| `identity_document_type` | `VARCHAR(16)` | | Ex.: CPF, RG, NIF — *lookup* opcional. |
| `identity_document_number` | `VARCHAR(32)` | | |
| `contract_type_id` | `SMALLINT` | FK `ref.contract_type` | Consumo / largura de banda / kWh / canais — parametrizado. |
| `first_connection_date` | `DATE` | | Primeira ligação à rede. |
| `connection_start_date` | `DATE` | | Início da ligação actual (pode diferir da primeira). |
| `connection_end_date` | `DATE` | | Desligamento. |
| `street_type` | `VARCHAR(64)` | | |
| `street_name` | `VARCHAR(64)` | | |
| `house_number` | `VARCHAR(10)` | | |
| `apartment_number` | `VARCHAR(10)` | | |
| `postal_code` | `VARCHAR(10)` | | |
| `city` | `VARCHAR(30)` | | |
| `state` | `VARCHAR(30)` | | |
| `primary_phone` | `VARCHAR(16)` | | |
| `secondary_phone` | `VARCHAR(16)` | | |
| `description` | `VARCHAR(80)` | | |
| `smart_meter` | `BOOLEAN` | | Substitui `NUMBER(1,0)`. |
| `location_description` | `VARCHAR(80)` | | Endereço textual completo. |
| `geom` | `geometry(Point, 4326)` | | Preferível a `lat`/`long` separados. |
| `accepts_proactive_contact` | `BOOLEAN` | | Equivalente ao conceito “CPA” / comunicação proactiva. |
| `utility_type` | `VARCHAR(16)` | | electric, gas, water, sewer, telecom. |

**Remoções / generalizações:** campos exclusivos de um único sector devem migrar para `JSONB attributes` ou tabelas filhas por utility, para não poluir o núcleo.

---

## 5. Domínio — Equipamentos (`network.equipment` proposta)

| Coluna (EN) | Tipo sugerido | Notas |
|-------------|---------------|--------|
| `id` | `BIGSERIAL` ou `VARCHAR(30)` UQ | Alinhar com identificadores legados se existirem. |
| `event_id` | `BIGINT` | |
| `equipment_type_id` | `SMALLINT` | FK `ref.equipment_type`. |
| `network_type_id` | `SMALLINT` | Primário, secundário, transmissão… |
| `network_level_id` | `SMALLINT` | Aéreo, subterrâneo, subaquático, interior… |
| `connection_status_0` … `_3` | `SMALLINT` | FK `ref.connection_state` — fases/conductores; na POC podem mapear A/B/C. |
| `normal_connection_status_0` … `_3` | `SMALLINT` | Estado “esperado” para comparação. |
| `monitoring_status_id` | `SMALLINT` | Ligado, desligado, sem comunicação. |
| `parent_equipment_id` | `VARCHAR(30)` | |
| `location_description` | `VARCHAR(80)` | |
| `geom` | `geometry(Point, 4326)` ou `geometry` mais rica | Poste, trecho, etc. |

---

## 6. Domínio — OMS

### 6.1 Chamada — `oms.call`

| Coluna (EN) | Tipo sugerido | Notas |
|-------------|---------------|--------|
| `id` | `BIGSERIAL` | |
| `event_id` | `BIGINT` | |
| `processor_id` | `BIGINT` | Associação / correlação entre ordens. |
| `call_type_id` | `INTEGER` | FK `ref.call_type`. |
| `neighborhood_id` | `BIGINT` | *Simple area* / bairro (pode FK `landbase` ou tabela de áreas). |
| `account_number` | `VARCHAR(30)` | FK → `customer.service_account`. |
| `originating_number` | `VARCHAR(32)` | Identificador externo na criação. |
| `description` | `VARCHAR(50)` | |
| `field_time_received` | `TIMESTAMPTZ` | Data informada na origem. |
| `system_time_received` | `TIMESTAMPTZ` | Definição no sistema (`now()`). |
| `received_by` | `VARCHAR(6)` | Canal de entrada — preferir FK `ref.intake_channel`. |
| `comments` | `VARCHAR(500)` | |
| `status` | `VARCHAR(16)` | default `open` — ou FK `ref.call_status`. |
| `scheduled_start_time` | `TIMESTAMPTZ` | |
| `informative` | `BOOLEAN` | |
| `predict_outage` | `BOOLEAN` | `1` = gera ordem com interrupção esperada. |
| `caller_name` | `VARCHAR(80)` | Substitui `NAME` ambíguo. |
| `contact_phone` | `VARCHAR(32)` | |
| `contact_email` | `VARCHAR(50)` | |
| `callback_required` | `BOOLEAN` | |
| `work_order_id` | `BIGINT` | FK → `oms.work_order`. |
| `handled_by_process_id` | `SMALLINT` | Processo que associou a ordem. |
| `system_generated` | `BOOLEAN` | Retorno proactivo / gerada pelo sistema (corrige typo `SYSMTe`). |
| `auto_callback_status_id` | `SMALLINT` | Calculado. |
| `human_callback_status_id` | `SMALLINT` | Calculado. |
| `location_resolved` | `BOOLEAN` | Localização encontrada no cadastro vs. geocodificada. |
| `location_description` | `VARCHAR(80)` | |
| `geom` | `geometry(Point, 4326)` | |

**Regra de negócio:** toda chamada relevante **gera** ou **associa** uma ordem (`work_order_id` preenchido após processamento).

### 6.2 Contato — `oms.call_feedback`

| Coluna (EN) | Tipo | Notas |
|-------------|------|--------|
| `id` | `BIGSERIAL` | |
| `event_id` | `BIGINT` | |
| `call_id` | `BIGINT` | NULL = contacto proactivo; pode originar `oms.call` de sistema. |
| `channel_id` | `SMALLINT` | Humano, automático, proactivo. |
| `system_message_template_id` | `SMALLINT` | Texto WhatsApp / SMS parametrizado. |
| `human_comment` | `VARCHAR(1000)` | |

### 6.3 Ordem — `oms.work_order` (modelo alvo; ver §9 para POC)

Campos do rascunho traduzidos para nomenclatura estável:

| Grupo | Colunas (resumo EN) |
|-------|---------------------|
| Identidade | `id`, `event_id`, `order_code` (UQ), `status_id`, `order_type_id`, `order_group` |
| Tempos / SLA | `time_dispatched`, `time_enroute`, `time_on_site`, `time_completed`, `etr` (estimated time restore), `duration_minutes` |
| Agregação chamadas | `number_of_calls`, `last_call_at` |
| Impacto | `customers_interrupted_current`, `chi`, `chi_projected`, `partial_duration_mean`, `critical_customers_affected` |
| Equipamento | `equipment_id`, `equipment_type_code` |
| Equipas | `num_crews_assigned`, `crew_owner_id`, `main_crew_id`, tempos por equipa (`prep_crew_1`, `prep_crew_2`) |
| Callback | `auto_callback_status_id`, `human_callback_status_id` |
| Filtros UI | `organization_id`, `operational_unit`, `etd` (texto ou FK conforme negócio) |
| Prioridade | `priority_score`, `reincident_flag`, `incident_status_id` |
| Planeamento | `planned_flag`, `operational_type_id` |
| IA / NLP (futuro) | `flag_burst_et`, `flag_sectioned_wire`, `distinct_callers_count`, `flag_broken_tree`, `flag_broken_pole` — *scores* ou booleanos derivados de análise de texto das chamadas |
| Geografia | `location_description`, `geom` (do equipamento afectado) |

**Nota:** `TP`, `TL`, `TR`, `TA` do rascunho devem documentar-se como **estados temporais** ou **durações** em tabela filha `oms.work_order_milestone` para auditoria fina.

### 6.4 Tarefa — `oms.task`

| Coluna (EN) | Notas |
|-------------|--------|
| `id`, `event_id` | |
| `work_order_id` | **FK BIGINT** (não `VARCHAR` da ordem). |
| `crew_assignment_id` | FK → `mwm.crew_order_assignment` |
| `task_type_id`, `task_status_id` | *Lookups*; incluir se o tipo gera interrupção. |
| `field_timestamp`, `system_timestamp` | |
| `equipment_id` | FK |
| `comments` | |
| `parent_task_id` | Hierarquia de tarefas (corrige `TASK_ID` FK para si próprio). |

### 6.5 Evento de rede — `oms.network_event`

Liga ordem, opcionalmente tarefa, equipamento e estados multi-fase (`connection_status_0`…`_3`), com `field_date` / `system_date`. Pode gerar registos em `oms.customer_interruption`.

### 6.6 Interrupção ao cliente — `oms.customer_interruption`

| Coluna | Notas |
|--------|--------|
| `customer_id` | FK `customer.service_account`. |
| `start_event_id`, `end_event_id` | FK evento de rede ou evento de domínio que abre/fecha a interrupção. |

---

## 7. Domínio — MWM

### 7.1 Equipa — `mwm.crew`

| Coluna (EN) | Notas |
|-------------|--------|
| `id`, `event_id` | |
| `crew_code`, `name`, `status_id`, `crew_type_id` | |
| `leader_name` | |
| `time_in_service`, `time_without_order` | Intervalo ou acumuladores conforme política. |
| `last_order_id`, `current_order_id`, `next_order_id` | FKs opcionais. |
| `operational_base`, `organization_id` | |
| `last_crew_update_at`, `last_coord_update_at` | |
| `current_neighborhood_id` | *Bairro actual*. |
| `last_known_geom` | PostGIS |

### 7.2 Turno — `mwm.crew_shift`

`crew_id`, `event_id`, `shift_availability_start`, `shift_availability_end`, `last_change_at`.

### 7.3 Atribuição equipa–ordem — `mwm.crew_order_assignment`

Equivalente a `CREW_ORDER_RELATION`: `order_id`, `task_id`, `crew_id`, `status`, `assigned_at`, `dispatched_at`, `enroute_at`, `arrived_at`, `released_at`, `is_main_crew`.  
**Integridade:** `ON DELETE` deve ser **RESTRICT** ou **arquivo** em auditoria — evitar `CASCADE` cego em ordens fechadas.

### 7.4 Trajectos — `mwm.crew_route_daily` / histórico

- **Dia actual / anterior:** `geometry(MultiLineString, 4326)` ou `GEOGRAPHY` + `tracked_at[]` em `JSONB` normalizado para pontos ordenados.  
- **Histórico:** partição por data ou janela (`operations.team_route` na POC já usa `window_start` / `window_end` + `route_geom`).

---

## 8. Eventos e auditoria unificados (proposta)

**Tabela canónica** `audit.domain_event` (ou `oms.domain_event`):

- `id`, `occurred_at`, `actor_user_id`, `source` (ui, bot, integration), `payload JSONB`, `correlation_id`.

Todas as entidades mutáveis referenciam `event_id` para a **última** alteração conhecida; histórico completo pode estar em `audit.*_history` (tipo SCD2) ou em **event sourcing** leve via MongoDB (`event_report`) para telemetria de alta frequência, conforme arquitectura TabGis.

**Política DELETE:** manter `audit.operations_row_archive` (padrão actual) e replicar o padrão para `oms.*` / `customer.*` críticos.

---

## 9. Alinhamento com a implementação actual (POC)

| Conceito rascunho | TabGis hoje (`operations`) |
|-------------------|------------------------------|
| Equipa | `operations.team` |
| Ordem | `operations.work_order` (`order_code`, `category`, `status`, …) |
| Relação equipa–ordem + tempos | `operations.team_order_displacement` |
| Rota temporal | `operations.team_route` |
| Arquivo pré-delete | `audit.operations_row_archive` + triggers |

A evolução natural é **migrar** `operations.work_order` para o modelo `oms.work_order` expandido, preservando códigos e chaves, ou **renomear schema** `operations` → `oms` após compatibilização.

---

## 10. Artefactos relacionados

| Ficheiro | Conteúdo |
|----------|----------|
| `docs/Database_Structure_Context.html` | Diagramas ER e fluxos (Mermaid). |
| `infra/sql/01_init_schemas.sql` | `config`, `security`, `audit` (base). |
| `infra/sql/03_operations_schema.sql` | POC operações / MWM mínimo. |
| `docs/CONTEXT_STATE.md` | Estado da stack e referência rápida. |

---

## 11. Resumo de decisões de limpeza (rascunho → modelo)

- Corrigir typos: `PARENTE` → **parent**, `SYSMTe` → **system_generated**, `Numeber` → **numeric type**.  
- `HUMAN_MSG NUMBER(1000)` → **VARCHAR(1000)**.  
- Flags vindos de texto de chamada (**árvore**, **poste**, fio partido, etc.) → colunas **`flag_*`** documentadas + pipeline IA opcional.  
- Coordenadas → **PostGIS**; rotas → **LineString/MultiLineString** ou pontos timestampados.  
- **TYPE** / **STATUS** → chaves estrangeiras para `ref.*`, todos auditáveis.

---

*Documento gerado a partir de `Database_Structure_Context.md` (rascunho inicial) e alinhado ao projecto TabGis / GeoUtil.*
