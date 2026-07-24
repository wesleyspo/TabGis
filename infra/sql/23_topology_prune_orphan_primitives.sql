-- ============================================================================
-- TabGis — Limpeza de primitivas órfãs da topologia tabgis_utilities_topo
-- ============================================================================
-- Contexto: apagar um segmento (DELETE /api/topology/spans/:id) liberta as
-- relações da TopoGeometry (clearTopoGeom), mas as primitivas edge_data/node
-- sem referência permanecem — comportamento nativo do postgis_topology.
-- Esta rotina remove-as com as funções oficiais do motor:
--   * ST_RemEdgeModFace  — remove aresta e funde faces adjacentes;
--   * ST_RemIsoNode      — remove nó isolado (sem arestas incidentes).
--
-- Ordem de aplicação: após 22_topology_span_write_support.sql.
-- API: POST /api/topology/maintenance/prune (backend/server.js).
-- Documentação: docs/mds/TOPOLOGY_NATIVE_POSTGIS.md §5.
-- ============================================================================

CREATE OR REPLACE FUNCTION gis.prune_orphan_topology_primitives(p_dry_run boolean DEFAULT false)
RETURNS TABLE (
  orphan_edges_found integer,
  edges_removed integer,
  isolated_nodes_found integer,
  nodes_removed integer
)
LANGUAGE plpgsql
AS $$
DECLARE
  v_edge RECORD;
  v_node RECORD;
  v_orphan_edges integer := 0;
  v_edges_removed integer := 0;
  v_iso_nodes integer := 0;
  v_nodes_removed integer := 0;
BEGIN
  -- Arestas sem qualquer referência em relation (element_type = 2, id com sinal)
  FOR v_edge IN
    SELECT e.edge_id
    FROM tabgis_utilities_topo.edge_data e
    WHERE NOT EXISTS (
      SELECT 1
      FROM tabgis_utilities_topo.relation r
      WHERE r.element_type = 2
        AND abs(r.element_id) = e.edge_id
    )
    ORDER BY e.edge_id
  LOOP
    v_orphan_edges := v_orphan_edges + 1;
    IF NOT p_dry_run THEN
      BEGIN
        PERFORM topology.ST_RemEdgeModFace('tabgis_utilities_topo', v_edge.edge_id);
        v_edges_removed := v_edges_removed + 1;
      EXCEPTION WHEN OTHERS THEN
        -- Aresta pode ter ficado estrutural para outra feição; regista e segue.
        RAISE NOTICE 'prune: edge % não removida: %', v_edge.edge_id, SQLERRM;
      END;
    END IF;
  END LOOP;

  -- Nós isolados: sem arestas incidentes e sem referência em relation (element_type = 1)
  FOR v_node IN
    SELECT n.node_id
    FROM tabgis_utilities_topo.node n
    WHERE NOT EXISTS (
      SELECT 1 FROM tabgis_utilities_topo.edge_data e
      WHERE e.start_node = n.node_id OR e.end_node = n.node_id
    )
    AND NOT EXISTS (
      SELECT 1
      FROM tabgis_utilities_topo.relation r
      WHERE r.element_type = 1
        AND r.element_id = n.node_id
    )
    ORDER BY n.node_id
  LOOP
    v_iso_nodes := v_iso_nodes + 1;
    IF NOT p_dry_run THEN
      BEGIN
        PERFORM topology.ST_RemIsoNode('tabgis_utilities_topo', v_node.node_id);
        v_nodes_removed := v_nodes_removed + 1;
      EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'prune: node % não removido: %', v_node.node_id, SQLERRM;
      END;
    END IF;
  END LOOP;

  RETURN QUERY SELECT v_orphan_edges, v_edges_removed, v_iso_nodes, v_nodes_removed;
END;
$$;

COMMENT ON FUNCTION gis.prune_orphan_topology_primitives(boolean) IS
  'Remove arestas/nós de tabgis_utilities_topo sem referência de TopoGeometry (órfãos pós-DELETE de gis.network_span). p_dry_run=true só conta, não remove. Exposta em POST /api/topology/maintenance/prune.';
