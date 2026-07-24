# TabGis — Especificação de dados (utilities)

> **Convenção deste documento:** cada entidade é uma **tabela** com colunas **Campo**, **Tipo (PostgreSQL)**, **Comentário (inglês, US)** e **Comentário (português)**. Nomes de **schemas**, **tabelas** e **campos** em **inglês**.  
> **Motor:** PostgreSQL 15+ / PostGIS. Campos `TYPE` / `STATUS` com domínio fechado exigem **tabela de controlo** correspondente (cadastro + auditoria), conforme regra global do modelo.  
> **Diagramas:** versão HTML gerada a partir deste MD em [`../html/Database_Structure_Context.html`](../html/Database_Structure_Context.html); diagrama interactivo legado em [`../html/Database_Structure_Context.diagram-legacy.html`](../html/Database_Structure_Context.diagram-legacy.html).

---

## 1. Partição de schemas (definição do modelo)

| Schema | Conteúdo |
|--------|------------|
| **`gis`** | **Consumidores** (*consumers*) e **equipamentos** (*equipment*) da rede — dados espaciais e cadastro de ativos / pontos de entrega. |
| **`oms`** | **Chamadas** (*calls*), **feedbacks** de contato, **ordens** (*work orders*), **tarefas** (*tasks*), **eventos de rede** (*network events*), **interrupções ao consumidor** (*customer interruptions*). |
| **`mwm`** | **Equipas** (*crews*), **turnos**, **atribuição equipa–ordem**, **trajectos** (tempo real / histórico). |

**Schemas já existentes no projecto (fora desta partição):** `landbase` (fundo cartográfico), `config`, `security`, `audit`, **`events`** (diário append-only de integração — ver `docs/mds/EVENTS_ARCHITECTURE.md`), **`schematic`** (vistas unifilares / fluxo com foco geográfico), **`tabgis_utilities_topo`** (topologia PostGIS nativa — primitivas `edge_data`/`node`/…; ver `docs/mds/TOPOLOGY_NATIVE_POSTGIS.md`). A POC `operations.*` é subconjunto temporário até alinhar DDL com `oms` / `mwm`.

---

## 2. Dependências entre entidades (FK lógicas)

| Origem | Campo | Destino | Notas |
|--------|-------|---------|--------|
| `gis.equipment` | `parent_equipment_id` | `gis.equipment.id` | Hierarquia de alimentação (opcional). |
| `gis.consumer` | `equipment_id` | `gis.equipment.id` | Equipamento que serve o ponto de entrega. |
| `gis.consumer` | `parent_equipment_id` | `gis.equipment.id` | Equipamento “pai” na topologia. |
| `oms.call` | `consumer_id` | `gis.consumer.id` | Opcional até resolução cadastral. |
| `oms.call` | `work_order_id` | `oms.work_order.id` | Chamada gera ou associa ordem. |
| `oms.call_feedback` | `call_id` | `oms.call.id` | Nulo se contato exclusivamente proactivo. |
| `oms.work_order` | `equipment_id` | `gis.equipment.id` | Equipamento afetado. |
| `oms.work_order` | `owner_id` | `security.users.id` | Utilizador responsável pela ordem (POC). |
| `oms.work_order` | `locked_by_id` | `security.users.id` | Utilizador que detém bloqueio de edição (POC). |
| `oms.task` | `work_order_id` | `oms.work_order.id` | |
| `oms.task` | `equipment_id` | `gis.equipment.id` | |
| `oms.task` | `parent_task_id` | `oms.task.id` | Hierarquia de tarefas. |
| `oms.network_event` | `work_order_id` | `oms.work_order.id` | |
| `oms.network_event` | `task_id` | `oms.task.id` | Opcional. |
| `oms.network_event` | `equipment_id` | `gis.equipment.id` | |
| `oms.customer_interruption` | `consumer_id` | `gis.consumer.id` | |
| `mwm.crew_order_assignment` | `crew_id` | `mwm.crew.id` | |
| `mwm.crew_order_assignment` | `work_order_id` | `oms.work_order.id` | |
| `mwm.crew_order_assignment` | `task_id` | `oms.task.id` | Opcional. |
| `mwm.crew_shift` | `crew_id` | `mwm.crew.id` | |
| `mwm.crew_route_daily` | `crew_id` | `mwm.crew.id` | |
| `mwm.crew_route_history` | `crew_id` | `mwm.crew.id` | |
| Todas as tabelas de negócio abaixo | `event_id` | `audit.domain_event.id` | Última alteração rastreada (ver §8). |

---

## 3. Schema `gis`

### 3.1 `gis.consumer` (consumidor / conta contratual)

| Campo | Tipo | Comentário (EN) | Comentário (PT) |
|-------|------|-----------------|-----------------|
| `id` | `BIGSERIAL` | Primary key. | Chave primária. |
| `event_id` | `BIGINT` | FK to `audit.domain_event`; last change tracking. | FK evento de alteração; rastreio da última mudança. |
| `account_number` | `VARCHAR(30)` | Unique commercial account identifier. | Identificador único da conta comercial. |
| `status_id` | `SMALLINT` | FK to controlled status table (active, suspended, etc.). | FK tabela de estados possíveis do cadastro. |
| `type_id` | `SMALLINT` | FK to controlled consumer type table; audited. | FK tabela de **TYPE**; cadastro e auditoria obrigatórios. |
| `equipment_id` | `VARCHAR(30)` | Served network equipment identifier (FK to `gis.equipment` by business key or id). | ID do equipamento de rede servido. |
| `parent_equipment_id` | `VARCHAR(30)` | Upstream feeding equipment identifier. | ID do equipamento que alimenta (pai). |
| `last_name` | `VARCHAR(64)` | Customer last name. | Apelido / nome de família. |
| `first_name` | `VARCHAR(64)` | Customer first name. | Primeiro nome. |
| `email` | `VARCHAR(255)` | Contact email. | E-mail de contacto. |
| `identity_document_type` | `VARCHAR(16)` | ID document type (CPF, RG, etc.). | Tipo de documento de identidade. |
| `identity_document_number` | `VARCHAR(32)` | ID document number. | Número do documento. |
| `contract_type_id` | `SMALLINT` | FK to contract type (consumption tier, Mbps, kWh, channels). | FK tipo de contrato; tabela de controle. |
| `first_connection_date` | `DATE` | First grid connection date. | Data da primeira ligação à rede. |
| `connection_start_date` | `DATE` | Start of current connection period. | Início do período de ligação actual. |
| `connection_end_date` | `DATE` | Grid disconnection date; nullable. | Data de desligamento da rede. |
| `street_type` | `VARCHAR(64)` | Street type prefix. | Tipo de logradouro. |
| `street_name` | `VARCHAR(64)` | Street name. | Nome da via. |
| `house_number` | `VARCHAR(10)` | Street number. | Número. |
| `apartment_number` | `VARCHAR(10)` | Apartment / unit. | Apartamento / unidade. |
| `postal_code` | `VARCHAR(10)` | Postal code. | Código postal. |
| `city` | `VARCHAR(30)` | City. | Cidade. |
| `state` | `VARCHAR(30)` | State / region. | Estado / região. |
| `primary_phone_number` | `VARCHAR(16)` | Primary phone. | Telefone principal. |
| `secondary_phone_number` | `VARCHAR(16)` | Secondary phone. | Telefone secundário. |
| `description` | `VARCHAR(80)` | Short free-text description. | Descrição curta. |
| `smart_meter` | `BOOLEAN` | Smart meter installed flag. | Indicador de medidor inteligente. |
| `location_desc` | `VARCHAR(80)` | Full address text. | Endereço completo em texto. |
| `geom` | `geometry(Point,4326)` | Service location; prefer over raw lat/long. | Localização do serviço (PostGIS). |
| `accepts_proactive_contact` | `BOOLEAN` | Customer accepts proactive outreach (CPA). | Aceita comunicação proactiva (CPA). |
| `utility_domain` | `VARCHAR(16)` | Utility sector: electric, gas, water, sewer, telecom. | Sector: energia, gás, água, esgoto, telecom. |

### 3.2 `gis.equipment`

| Campo | Tipo | Comentário (EN) | Comentário (PT) |
|-------|------|-----------------|-----------------|
| `id` | `BIGSERIAL` | Primary key (or align with legacy VARCHAR key via unique constraint). | Chave primária. |
| `event_id` | `BIGINT` | FK to `audit.domain_event`. | FK evento de alteração. |
| `type_id` | `SMALLINT` | FK to equipment **TYPE** table; audited. | FK **TYPE** de equipamento; auditado. |
| `network_type_id` | `SMALLINT` | FK primary / secondary / transmission / generation. | FK tipo de rede (primário, secundário, transmissão…). |
| `network_level_id` | `SMALLINT` | FK aerial / underground / submarine / indoor. | FK nível (aéreo, subterrâneo…). |
| `status_0` | `SMALLINT` | Connection state phase 0 (connected / disconnected / predicted). | Estado de ligação fase 0. |
| `status_1` | `SMALLINT` | Phase A (multi-phase / multi-circuit). | Fase A (POC). |
| `status_2` | `SMALLINT` | Phase B. | Fase B (POC). |
| `status_3` | `SMALLINT` | Phase C. | Fase C (POC). |
| `normal_status_0` | `SMALLINT` | Expected normal state phase 0. | Estado normal fase 0. |
| `normal_status_1` | `SMALLINT` | Expected normal phase A. | Estado normal fase A. |
| `normal_status_2` | `SMALLINT` | Expected normal phase B. | Estado normal fase B. |
| `normal_status_3` | `SMALLINT` | Expected normal phase C. | Estado normal fase C. |
| `monitoring_status_id` | `SMALLINT` | Telemetry link: connected / disconnected / no comm. | Estado de monitorização / comunicação. |
| `parent_equipment_id` | `VARCHAR(30)` | Upstream feeding equipment id. | ID do equipamento que alimenta. |
| `location_desc` | `VARCHAR(80)` | Location text. | Endereço ou descrição de local. |
| `geom` | `geometry(Geometry,4326)` | Equipment geometry (point or line). | Geometria PostGIS do ativo. |

*Nota:* Estados `status_*` / `normal_status_*` devem referenciar tabelas de domínio (ex.: `ref.connection_state`) com o mesmo significado em todos os utilities.

### 3.3 `gis.network_span` (segmento linear da rede + TopoGeometry)

Entidade de **segmento linear da rede** (em inglês de dados: *network span*): continuidade física gerida pela extensão **`postgis_topology`**. DDL e dados demo: `infra/sql/21_postgis_topology_utilities.sql`. Vista legível: **`gis.v_network_span_readable`**.

| Campo | Tipo | Comentário (EN) | Comentário (PT) |
|-------|------|-----------------|-----------------|
| `id` | `BIGSERIAL` | Primary key. | Chave primária. |
| `code` | `VARCHAR(96)` | Unique business code for the span. | Código único do segmento linear. |
| `description` | `TEXT` | Optional operator-facing note. | Nota opcional. |
| `utility_domain` | `VARCHAR(16)` | Sector (electric, gas, water, …). | Sector utility. |
| `equipment_from_id` | `BIGINT` | Optional upstream terminal equipment. | Equipamento terminal inicial (opcional). |
| `equipment_to_id` | `BIGINT` | Optional downstream terminal equipment. | Equipamento terminal final (opcional). |
| `span_geom` | `geometry(LineString,4326)` | Exchange geometry (WFS/GeoJSON). | Geometria interoperável. |
| `topo_geom` | `topology.TopoGeometry` | Native topology reference (shared nodes). | Referência topológica nativa (nós partilhados). |
| `event_id` | `BIGINT` | FK `audit.domain_event`; optional. | Última alteração de domínio (opcional). |
| `metadata` | `JSONB` | Free-form span metadata. | Metadados livres. |
| `created_at` | `TIMESTAMPTZ` | Row creation time. | Criação do registo. |

---

## 4. Schema `oms`

### 4.1 `oms.call` (chamada — gera ou associa ordem)

| Campo | Tipo | Comentário (EN) | Comentário (PT) |
|-------|------|-----------------|-----------------|
| `id` | `BIGSERIAL` | Primary key. | Chave primária. |
| `event_id` | `BIGINT` | FK to `audit.domain_event`. | FK evento de alteração. |
| `processor_id` | `BIGINT` | Correlation / merge key for order association. | Controle de associação entre ordens. |
| `type_id` | `INTEGER` | Call **TYPE**; FK controlled table, audited. | **TYPE** da chamada; tabela de controle auditada. |
| `simple_area_id` | `BIGINT` | Neighborhood / simple area id (e.g. landbase link). | ID do bairro / área simples. |
| `consumer_id` | `BIGINT` | FK `gis.consumer.id` when resolved. | FK consumidor após resolução. |
| `account_number` | `VARCHAR(30)` | Account from intake; matches `gis.consumer.account_number`. | Número de conta (entrada). |
| `originating_number` | `VARCHAR(32)` | External id at creation. | Número externo informado na criação. |
| `description` | `VARCHAR(50)` | Short description. | Descrição breve. |
| `field_time_received` | `TIMESTAMPTZ` | External-reported receipt time. | Data/hora informada na origem. |
| `system_time_received` | `TIMESTAMPTZ` | System ingest time. | Data/hora de entrada no sistema. |
| `received_by` | `VARCHAR(6)` | Intake channel code. | Canal de entrada. |
| `comments` | `VARCHAR(500)` | Caller / agent comments. | Comentários do cliente / registo. |
| `status` | `VARCHAR(16)` | Call status; default `open`. | Estado da chamada. |
| `scheduled_start_time` | `TIMESTAMPTZ` | Scheduled window start. | Início agendado. |
| `informative` | `BOOLEAN` | Informative-only flag. | Chamada apenas informativa. |
| `predict` | `BOOLEAN` | If true, expect outage-related order. | Se verdadeiro, gera ordem com interrupção esperada. |
| `caller_name` | `VARCHAR(80)` | Name provided by caller. | Nome informado. |
| `contact_no` | `VARCHAR(32)` | Phone provided. | Telefone informado. |
| `email` | `VARCHAR(50)` | Email provided. | E-mail informado. |
| `callback` | `BOOLEAN` | Callback status flag. | Estado de callback. |
| `work_order_id` | `BIGINT` | Related work order FK. | Ordem relacionada. |
| `handled_by` | `SMALLINT` | Process that linked order; FK control table. | Processo que associou a ordem. |
| `system_generated` | `BOOLEAN` | System- or proactive-generated call. | Chamada gerada pelo sistema / proactiva. |
| `auto_callback_status` | `SMALLINT` | Derived automatic callback status. | Estado calculado — callback automático. |
| `human_callback_status` | `SMALLINT` | Derived human callback status. | Estado calculado — callback humano. |
| `location_resolved` | `BOOLEAN` | True if location matched registry vs geocoded. | Localização encontrada no cadastro vs. calculada. |
| `location_desc` | `VARCHAR(80)` | Address text as reported. | Endereço informado. |
| `geom` | `geometry(Point,4326)` | Call location. | Localização da chamada. |

### 4.2 `oms.call_feedback` (contato com consumidor)

| Campo | Tipo | Comentário (EN) | Comentário (PT) |
|-------|------|-----------------|-----------------|
| `id` | `BIGSERIAL` | Primary key. | Chave primária. |
| `event_id` | `BIGINT` | FK to `audit.domain_event`. | FK evento de alteração. |
| `call_id` | `BIGINT` | FK `oms.call`; null if proactive-only contact. | FK chamada; nulo se só contato proactivo. |
| `channel_id` | `SMALLINT` | Channel **TYPE** (human, automatic, proactive); audited. | Canal; tabela **CHANNEL** auditada. |
| `system_msg_id` | `SMALLINT` | Template id for WhatsApp/SMS text; audited. | FK mensagem de sistema (ex.: WhatsApp). |
| `human_msg` | `VARCHAR(1000)` | Human agent free-text comment. | Comentário do contacto humano. |

### 4.3 `oms.work_order`

| Campo | Tipo | Comentário (EN) | Comentário (PT) |
|-------|------|-----------------|-----------------|
| `id` | `BIGSERIAL` | Primary key. | Chave primária. |
| `event_id` | `BIGINT` | FK to `audit.domain_event`. | FK evento de alteração. |
| `order_number` | `VARCHAR(24)` | Unique business order number. | Número único da ordem. |
| `status` | `VARCHAR(32)` | Order lifecycle status. | Estado da ordem. |
| `type_id` | `SMALLINT` | Order **TYPE**; FK; audited. | **TYPE** da ordem; controle auditado. |
| `order_group` | `VARCHAR(14)` | Grouping code. | Código de grupo. |
| `aval_dif` | `SMALLINT` | Evaluation / difficulty flag. | Flag de avaliação / dificuldade. |
| `metric_tp` | `NUMERIC` | Dispatch phase metric (legacy TP). | Métrica fase despacho (TP legado). |
| `metric_tl` | `NUMERIC` | En route duration metric (TL). | Métrica tempo a caminho (TL). |
| `metric_tr` | `NUMERIC` | Field completion metric (TR). | Métrica conclusão em campo (TR). |
| `metric_ta` | `NUMERIC` | Alternate completion metric (TA). | Métrica alternativa de conclusão (TA). |
| `base_op` | `TEXT` | Operational base filter text. | Base operacional (filtro). |
| `micro_region` | `TEXT` | Micro-region filter. | Micro-região. |
| `feeder` | `TEXT` | Feeder code / name. | Alimentador. |
| `outage_count` | `INTEGER` | Interruption count. | Número de interrupções. |
| `customers_interrupted_current` | `INTEGER` | Currently interrupted customers (derived). | Clientes actualmente interrompidos (calculado). |
| `number_of_calls` | `INTEGER` | Call count (from calls). | Número de chamadas associadas. |
| `last_call_at` | `TIMESTAMPTZ` | Last related call timestamp. | Data/hora da última chamada. |
| `duration_minutes` | `INTEGER` | Computed duration minutes. | Duração em minutos (calculada). |
| `chi` | `TEXT` | Customer-hours interrupted aggregate string/detail. | CHI — agregado afetados × horas. |
| `dm_partial` | `NUMERIC` | Partial mean duration (CHI / affected). | Duração média parcial. |
| `chi_projected` | `NUMERIC` | Projected CHI (current + CI × ETR). | CHI projetado. |
| `equipment_id` | `BIGINT` | FK `gis.equipment.id`. | Equipamento afetado. |
| `equipment_type_code` | `VARCHAR(10)` | Equipment type shortcut FK / denormalized. | Tipo de equipamento (atalho). |
| `crew_count` | `INTEGER` | Assigned crew count. | Número de equipas atribuídas. |
| `prep_crew_1` | `NUMERIC` | First crew prep time metric. | Tempo preparo equipa 1 (calculado). |
| `prep_crew_2` | `NUMERIC` | Second crew prep time metric. | Tempo preparo equipa 2 (calculado). |
| `etr` | `TIMESTAMPTZ` | Estimated time of restoration. | Tempo estimado de restauro. |
| `auto_callback_status` | `SMALLINT` | Derived auto callback. | Callback automático (calculado). |
| `human_callback_status` | `SMALLINT` | Derived human callback. | Callback humano (calculado). |
| `organization_label` | `VARCHAR(50)` | Organization filter label. | Organização (filtro UI). |
| `etd` | `TEXT` | ETD filter / text. | ETD (filtro). |
| `complaint_summary` | `VARCHAR(512)` | Derived complaint summary. | Resumo de reclamações (calculado). |
| `priority` | `INTEGER` | Priority score. | Prioridade (calculada ou manual). |
| `comment` | `VARCHAR(1000)` | Internal comment. | Comentário interno. |
| `customer_message` | `VARCHAR(255)` | Outbound message to customer. | Mensagem para o cliente. |
| `organization_id` | `INTEGER` | Organization FK for filters. | ID organização (filtro). |
| `order_created_at` | `TIMESTAMPTZ` | Order creation time. | Data de criação da ordem. |
| `outage_start_time` | `TIMESTAMPTZ` | Outage / work start for filters. | Início da interrupção / trabalho. |
| `crew_owner_id` | `BIGINT` | FK crew that owns edit rights via assignment. | Equipa “dona” — pode editar a ordem. |
| `main_crew_id` | `BIGINT` | First / primary assigned crew. | Primeira equipa associada. |
| `owner_id` | `INTEGER` | FK `security.users.id`; human owner of the work order record. | Responsável (utilizador) pela ordem. |
| `locked_by_id` | `INTEGER` | FK `security.users.id`; optimistic edit lock (nullable). | Bloqueio de edição por utilizador. |
| `assigned_at` | `TIMESTAMPTZ` | First assignment timestamp. | Primeira atribuição. |
| `dispatched_at` | `TIMESTAMPTZ` | First dispatch timestamp. | Primeiro despacho. |
| `enroute_at` | `TIMESTAMPTZ` | First en-route timestamp. | Primeiro “a caminho”. |
| `on_site_at` | `TIMESTAMPTZ` | First on-site timestamp. | Primeiro “no local”. |
| `released_at` | `TIMESTAMPTZ` | First release / clear timestamp. | Primeira liberação. |
| `rank_priority` | `NUMERIC` | Calculated rank vs all orders in base. | Prioridade relativa na base. |
| `repeat_incident` | `VARCHAR(3)` | Repeat / reincident flag. | Reincidente (calculado). |
| `incident_status` | `VARCHAR(40)` | Incident status; FK **TYPE** table. | Estado do incidente; tabela de **TYPE**. |
| `planned_flag` | `SMALLINT` | Planned order flag. | Ordem planejada. |
| `operational_type` | `VARCHAR(16)` | Operational subtype; FK **TYPE**. | Subtipo operacional. |
| `burst_et_calls` | `INTEGER` | NLP/IA flag count — burst / oil / fire patterns in calls. | Padrão ET / óleo / fogo (IA sobre texto). |
| `sectioned_wire_calls` | `INTEGER` | NLP/IA flag — broken conductor mentions. | Fio partido — padrão em chamadas. |
| `distinct_calls` | `INTEGER` | Distinct caller / call count metric. | Chamadas distintas (calculado). |
| `broken_tree` | `INTEGER` | NLP/IA flag — fallen tree on network. | Árvore caída (texto / IA). |
| `broken_pole` | `INTEGER` | NLP/IA flag — broken pole. | Poste caído (texto / IA). |
| `operational_unit` | `TEXT` | Operational unit (UO). | Unidade operacional. |
| `location_desc` | `VARCHAR(80)` | Derived from affected equipment. | Localização (do equipamento). |
| `geom` | `geometry(Geometry,4326)` | Derived equipment geometry. | Coordenadas do equipamento afetado. |
| `critical_customers` | `INTEGER` | Count of critical customers affected. | Consumidores críticos afectados. |

### 4.4 `oms.task`

| Campo | Tipo | Comentário (EN) | Comentário (PT) |
|-------|------|-----------------|-----------------|
| `id` | `BIGSERIAL` | Primary key. | Chave primária. |
| `event_id` | `BIGINT` | FK to `audit.domain_event`. | FK evento de alteração. |
| `work_order_id` | `BIGINT` | FK `oms.work_order`. | FK ordem. |
| `crew_assignment_id` | `BIGINT` | FK `mwm.crew_order_assignment`. | FK relação equipa–ordem. |
| `type_id` | `SMALLINT` | Task **TYPE**; may imply outage; audited. | **TYPE** da tarefa; pode gerar interrupção. |
| `status_id` | `SMALLINT` | Task status; audited. | Estado da tarefa. |
| `field_date` | `TIMESTAMPTZ` | Field-reported time. | Data/hora de campo. |
| `system_date` | `TIMESTAMPTZ` | System-recorded time. | Data/hora de sistema. |
| `equipment_id` | `BIGINT` | FK `gis.equipment`. | Equipamento. |
| `comments` | `TEXT` | Task comments. | Comentários da tarefa. |
| `parent_task_id` | `BIGINT` | Parent task for hierarchy. | Tarefa pai. |

### 4.5 `oms.network_event` (pode gerar `customer_interruption`)

| Campo | Tipo | Comentário (EN) | Comentário (PT) |
|-------|------|-----------------|-----------------|
| `id` | `BIGSERIAL` | Primary key. | Chave primária. |
| `event_id` | `BIGINT` | FK to `audit.domain_event`. | FK evento de alteração. |
| `work_order_id` | `BIGINT` | FK `oms.work_order`. | Ordem. |
| `type_id` | `SMALLINT` | Network event **TYPE**; audited. | **TYPE** do evento de rede. |
| `field_date` | `TIMESTAMPTZ` | Field time. | Data de campo. |
| `system_date` | `TIMESTAMPTZ` | System time. | Data de sistema. |
| `equipment_id` | `BIGINT` | FK `gis.equipment`. | Equipamento. |
| `status_0` | `SMALLINT` | Connection state phase 0 after event. | Estado fase 0 após evento. |
| `status_1` | `SMALLINT` | Phase A. | Fase A. |
| `status_2` | `SMALLINT` | Phase B. | Fase B. |
| `status_3` | `SMALLINT` | Phase C. | Fase C. |
| `task_id` | `BIGINT` | Optional FK `oms.task`. | Tarefa opcional. |

### 4.6 `oms.customer_interruption`

| Campo | Tipo | Comentário (EN) | Comentário (PT) |
|-------|------|-----------------|-----------------|
| `id` | `BIGSERIAL` | Primary key. | Chave primária. |
| `consumer_id` | `BIGINT` | FK `gis.consumer.id`. | Consumidor interrompido. |
| `start_event_id` | `BIGINT` | FK opening event (`oms.network_event` or `audit.domain_event`). | Evento de início. |
| `end_event_id` | `BIGINT` | FK closing event; nullable while active. | Evento de fim. |

---

## 5. Schema `mwm`

### 5.1 `mwm.crew`

| Campo | Tipo | Comentário (EN) | Comentário (PT) |
|-------|------|-----------------|-----------------|
| `id` | `BIGSERIAL` | Primary key. | Chave primária. |
| `event_id` | `BIGINT` | FK to `audit.domain_event`. | FK evento de alteração. |
| `crew_code` | `VARCHAR(32)` | Unique crew code. | Código da equipa. |
| `name` | `VARCHAR(120)` | Crew display name. | Nome da equipa. |
| `status_id` | `SMALLINT` | Crew status; audited. | Estado da equipa. |
| `type_id` | `SMALLINT` | Crew **TYPE**; audited. | **TYPE** da equipa. |
| `leader_name` | `VARCHAR(120)` | Crew leader. | Líder. |
| `time_in_service` | `INTERVAL` | Cumulative time in service. | Tempo em serviço. |
| `last_order_id` | `BIGINT` | Last work order FK. | Última ordem. |
| `current_order_id` | `BIGINT` | Current work order FK. | Ordem actual. |
| `next_order_id` | `BIGINT` | Next work order FK. | Próxima ordem. |
| `idle_time` | `INTERVAL` | Time without order. | Tempo sem ordem. |
| `base_op` | `VARCHAR(120)` | Operational base. | Base operacional. |
| `organization_id` | `INTEGER` | Owning organization. | Organização. |
| `last_crew_update_at` | `TIMESTAMPTZ` | Last crew record update. | Última actualização da equipa. |
| `last_coord_update_at` | `TIMESTAMPTZ` | Last GPS / coord update. | Última actualização de coordenadas. |
| `current_neighborhood_id` | `BIGINT` | Current neighborhood id. | Bairro actual. |
| `geom` | `geometry(Point,4326)` | Last known position. | Última posição conhecida. |

### 5.2 `mwm.crew_shift`

| Campo | Tipo | Comentário (EN) | Comentário (PT) |
|-------|------|-----------------|-----------------|
| `id` | `BIGSERIAL` | Primary key. | Chave primária. |
| `crew_id` | `BIGINT` | FK `mwm.crew`. | Equipa. |
| `event_id` | `BIGINT` | FK to `audit.domain_event`. | FK evento de alteração. |
| `shift_availability_start` | `TIMESTAMPTZ` | Shift window start. | Início disponibilidade. |
| `shift_availability_end` | `TIMESTAMPTZ` | Shift window end. | Fim disponibilidade. |
| `last_change_at` | `TIMESTAMPTZ` | Last schedule change. | Última alteração do turno. |

### 5.3 `mwm.crew_order_assignment` (relação equipa–ordem)

| Campo | Tipo | Comentário (EN) | Comentário (PT) |
|-------|------|-----------------|-----------------|
| `id` | `BIGSERIAL` | Primary key. | Chave primária. |
| `event_id` | `BIGINT` | FK to `audit.domain_event`. | FK evento de alteração. |
| `work_order_id` | `BIGINT` | FK `oms.work_order`. | Ordem. |
| `task_id` | `BIGINT` | FK `oms.task`; optional. | Tarefa. |
| `crew_id` | `BIGINT` | FK `mwm.crew`. | Equipa. |
| `status` | `VARCHAR(16)` | Assignment lifecycle status. | Estado da atribuição. |
| `assigned_time` | `TIMESTAMPTZ` | Assigned timestamp. | Hora de atribuição. |
| `dispatched_time` | `TIMESTAMPTZ` | Dispatched timestamp. | Despacho. |
| `enroute_time` | `TIMESTAMPTZ` | En route timestamp. | A caminho. |
| `arrived_time` | `TIMESTAMPTZ` | Arrived on site. | Chegada ao local. |
| `released_time` | `TIMESTAMPTZ` | Released / cleared. | Liberação. |
| `is_main_crew` | `BOOLEAN` | Primary crew for this order. | Equipa principal. |

*Integridade:* evitar `ON DELETE CASCADE` cego; preferir `RESTRICT` ou arquivo em `audit` antes de apagar ordens históricas.

### 5.4 `mwm.crew_route_daily` (janela curta — hoje / ontem)

| Campo | Tipo | Comentário (EN) | Comentário (PT) |
|-------|------|-----------------|-----------------|
| `id` | `BIGSERIAL` | Primary key. | Chave primária. |
| `crew_id` | `BIGINT` | FK `mwm.crew`. | Equipa. |
| `event_id` | `BIGINT` | FK to `audit.domain_event`. | FK evento de alteração. |
| `locations_today` | `JSONB` | GeoJSON or array of timestamped points for current day. | Pontos do dia actual + horários. |
| `locations_yesterday` | `JSONB` | Previous day track. | Pontos do dia anterior. |
| `updated_at` | `TIMESTAMPTZ` | Last refresh. | Última actualização. |

### 5.5 `mwm.crew_route_history` (histórico parametrizável)

| Campo | Tipo | Comentário (EN) | Comentário (PT) |
|-------|------|-----------------|-----------------|
| `id` | `BIGSERIAL` | Primary key. | Chave primária. |
| `crew_id` | `BIGINT` | FK `mwm.crew`. | Equipa. |
| `event_id` | `BIGINT` | FK to `audit.domain_event`. | FK evento de alteração. |
| `window_start` | `TIMESTAMPTZ` | History window start. | Início da janela. |
| `window_end` | `TIMESTAMPTZ` | History window end. | Fim da janela. |
| `route_geom` | `geometry(MultiLineString,4326)` | Consolidated path. | Trajecto consolidado (PostGIS). |
| `source` | `VARCHAR(64)` | Tracker / AVL source system. | Origem do rasto. |

---

## 6. Evento de domínio e auditoria (`audit`)

### 6.1 `audit.domain_event` (rastreio de alterações — todas as tabelas acima)

| Campo | Tipo | Comentário (EN) | Comentário (PT) |
|-------|------|-----------------|-----------------|
| `id` | `BIGSERIAL` | Primary key; referenced by `event_id`. | Chave primária. |
| `occurred_at` | `TIMESTAMPTZ` | Event timestamp. | Momento do evento. |
| `actor_user_id` | `INTEGER` | FK `security.users` optional. | Utilizador actor. |
| `source` | `VARCHAR(32)` | ui, bot, integration, batch. | Origem (UI, robô, integração). |
| `payload` | `JSONB` | Optional change payload / diff. | Detalhe opcional da alteração. |
| `correlation_id` | `VARCHAR(64)` | Cross-service correlation. | ID de correlação. |

Tabela **analógica** por domínio (histórico append-only) e política de **arquivo antes de DELETE** replicam a ideia de `audit.operations_row_archive` já usada na POC.

### 6.2 `security.users` (utilizadores)

| Campo | Tipo | Comentário (EN) | Comentário (PT) |
|-------|------|-----------------|-----------------|
| `id` | `SERIAL` | Primary key. | Chave primária. |
| `username` | `VARCHAR(50)` | Unique login / handle. | Identificador único. |
| `email` | `VARCHAR(255)` | Contact email; optional in POC. | E-mail opcional na POC. |
| `first_name` / `last_name` | `VARCHAR(100)` | Display name parts. | Nome próprio / apelido. |
| `access_type` | `VARCHAR(20)` | `ADMIN`, `CONSULTA`, `OPERACAO`. | Perfil de acesso. |
| `status` | `VARCHAR(20)` | Session / account hint (`online`, `offline`, …). | Estado operacional. |
| `created_at` | `TIMESTAMPTZ` | Row creation. | Criação do registo. |
| `is_active` | `BOOLEAN` | Account enabled; used with RBAC groups (`security.user_group_member`). | Conta activa; usado com grupos RBAC. |

Grupos e privilégios (`security.privilege`, `security.user_group`, `security.group_privilege`, `security.user_group_member`): script `infra/sql/18_security_groups_privileges.sql`.

A tabela legada `security.user` é migrada para `security.users` via `infra/sql/01_init_schemas.sql` / `04_gis_oms_mwm_domain.sql`.

---

## 7. Schema `schematic` (vistas esquemáticas — TabGis actual)

DDL: `infra/sql/16_schematic_schema.sql`; ligação opcional de nós a inventário: `infra/sql/17_schematic_link_poc_equipment.sql`.

| Tabela | Função |
|--------|--------|
| `schematic.network_view` | Vista lógica (unifilar, fluxo de potência ou híbrida); metadados JSON (ex.: tensão, código de alimentador). |
| `schematic.view_node` | Nó ordenado (`seq_no`) no desenho; `focus_lat` / `focus_lng` para «Ir para o mapa»; `equipment_id` opcional → `gis.equipment`. |
| `schematic.view_edge` | Aresta entre nós; campos qualitativos de P/Q (kW / kVAr) para anotação MVP. |

---

## 8. POC `operations` (TabGis actual)

| `operations` | Mapa conceptual |
|----------------|-----------------|
| `operations.team` | → `mwm.crew` |
| `operations.work_order` | → `oms.work_order` (POC inclui `owner_id`, `locked_by_id` → `security.users`) |
| `operations.team_order_displacement` | → `mwm.crew_order_assignment` |
| `operations.team_route` | → `mwm.crew_route_history` |

---

*Documento orientado à partição **gis / oms / mwm**, ao **`schematic`** operacional e às dependências entre consumidores, equipamentos, chamadas, ordens, tarefas, eventos de rede e equipas.*
