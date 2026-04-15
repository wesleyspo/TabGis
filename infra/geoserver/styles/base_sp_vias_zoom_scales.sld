<?xml version="1.0" encoding="UTF-8"?>
<!-- Alinhado a landbase.via_zoom_config + escalas OGC. Aplicar a vias_sp e vias_alvo_sp. -->
<StyledLayerDescriptor version="1.0.0"
  xsi:schemaLocation="http://www.opengis.net/sld StyledLayerDescriptor.xsd"
  xmlns="http://www.opengis.net/sld"
  xmlns:ogc="http://www.opengis.net/ogc"
  xmlns:xlink="http://www.w3.org/1999/xlink"
  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <NamedLayer>
    <Name>base_sp:vias_sp</Name>
    <UserStyle>
      <Title>Vias por escala (zoom)</Title>
      <FeatureTypeStyle>
        <!-- motorway / trunk: visível afastado -->
        <Rule>
          <Name>motorway-trunk-casing</Name>
          <MaxScaleDenominator>500000000</MaxScaleDenominator>
          <ogc:Filter>
            <ogc:Or>
              <ogc:PropertyIsEqualTo><ogc:PropertyName>highway</ogc:PropertyName><ogc:Literal>motorway</ogc:Literal></ogc:PropertyIsEqualTo>
              <ogc:PropertyIsEqualTo><ogc:PropertyName>highway</ogc:PropertyName><ogc:Literal>trunk</ogc:Literal></ogc:PropertyIsEqualTo>
            </ogc:Or>
          </ogc:Filter>
          <LineSymbolizer><Stroke><CssParameter name="stroke">#f1c46a</CssParameter><CssParameter name="stroke-width">5.2</CssParameter></Stroke></LineSymbolizer>
        </Rule>
        <Rule>
          <Name>motorway-trunk</Name>
          <MaxScaleDenominator>500000000</MaxScaleDenominator>
          <ogc:Filter>
            <ogc:Or>
              <ogc:PropertyIsEqualTo><ogc:PropertyName>highway</ogc:PropertyName><ogc:Literal>motorway</ogc:Literal></ogc:PropertyIsEqualTo>
              <ogc:PropertyIsEqualTo><ogc:PropertyName>highway</ogc:PropertyName><ogc:Literal>trunk</ogc:Literal></ogc:PropertyIsEqualTo>
            </ogc:Or>
          </ogc:Filter>
          <LineSymbolizer><Stroke><CssParameter name="stroke">#f7d88f</CssParameter><CssParameter name="stroke-width">3.6</CssParameter></Stroke></LineSymbolizer>
        </Rule>
        <!-- primary -->
        <Rule>
          <Name>primary-casing</Name>
          <MaxScaleDenominator>8000000</MaxScaleDenominator>
          <ogc:Filter>
            <ogc:PropertyIsEqualTo><ogc:PropertyName>highway</ogc:PropertyName><ogc:Literal>primary</ogc:Literal></ogc:PropertyIsEqualTo>
          </ogc:Filter>
          <LineSymbolizer><Stroke><CssParameter name="stroke">#f6e2b2</CssParameter><CssParameter name="stroke-width">4.0</CssParameter></Stroke></LineSymbolizer>
        </Rule>
        <Rule>
          <Name>primary</Name>
          <MaxScaleDenominator>8000000</MaxScaleDenominator>
          <ogc:Filter>
            <ogc:PropertyIsEqualTo><ogc:PropertyName>highway</ogc:PropertyName><ogc:Literal>primary</ogc:Literal></ogc:PropertyIsEqualTo>
          </ogc:Filter>
          <LineSymbolizer><Stroke><CssParameter name="stroke">#ffffff</CssParameter><CssParameter name="stroke-width">2.4</CssParameter></Stroke></LineSymbolizer>
        </Rule>
        <!-- secondary -->
        <Rule>
          <Name>secondary-casing</Name>
          <MaxScaleDenominator>2500000</MaxScaleDenominator>
          <ogc:Filter>
            <ogc:PropertyIsEqualTo><ogc:PropertyName>highway</ogc:PropertyName><ogc:Literal>secondary</ogc:Literal></ogc:PropertyIsEqualTo>
          </ogc:Filter>
          <LineSymbolizer><Stroke><CssParameter name="stroke">#f6e2b2</CssParameter><CssParameter name="stroke-width">3.4</CssParameter></Stroke></LineSymbolizer>
        </Rule>
        <Rule>
          <Name>secondary</Name>
          <MaxScaleDenominator>2500000</MaxScaleDenominator>
          <ogc:Filter>
            <ogc:PropertyIsEqualTo><ogc:PropertyName>highway</ogc:PropertyName><ogc:Literal>secondary</ogc:Literal></ogc:PropertyIsEqualTo>
          </ogc:Filter>
          <LineSymbolizer><Stroke><CssParameter name="stroke">#ffffff</CssParameter><CssParameter name="stroke-width">2.0</CssParameter></Stroke></LineSymbolizer>
        </Rule>
        <!-- tertiary -->
        <Rule>
          <Name>tertiary-casing</Name>
          <MaxScaleDenominator>600000</MaxScaleDenominator>
          <ogc:Filter>
            <ogc:PropertyIsEqualTo><ogc:PropertyName>highway</ogc:PropertyName><ogc:Literal>tertiary</ogc:Literal></ogc:PropertyIsEqualTo>
          </ogc:Filter>
          <LineSymbolizer><Stroke><CssParameter name="stroke">#d9d9d9</CssParameter><CssParameter name="stroke-width">2.7</CssParameter></Stroke></LineSymbolizer>
        </Rule>
        <Rule>
          <Name>tertiary</Name>
          <MaxScaleDenominator>600000</MaxScaleDenominator>
          <ogc:Filter>
            <ogc:PropertyIsEqualTo><ogc:PropertyName>highway</ogc:PropertyName><ogc:Literal>tertiary</ogc:Literal></ogc:PropertyIsEqualTo>
          </ogc:Filter>
          <LineSymbolizer><Stroke><CssParameter name="stroke">#ffffff</CssParameter><CssParameter name="stroke-width">1.6</CssParameter></Stroke></LineSymbolizer>
        </Rule>
        <!-- residential / living_street -->
        <Rule>
          <Name>residential-casing</Name>
          <MaxScaleDenominator>150000</MaxScaleDenominator>
          <ogc:Filter>
            <ogc:Or>
              <ogc:PropertyIsEqualTo><ogc:PropertyName>highway</ogc:PropertyName><ogc:Literal>residential</ogc:Literal></ogc:PropertyIsEqualTo>
              <ogc:PropertyIsEqualTo><ogc:PropertyName>highway</ogc:PropertyName><ogc:Literal>living_street</ogc:Literal></ogc:PropertyIsEqualTo>
            </ogc:Or>
          </ogc:Filter>
          <LineSymbolizer><Stroke><CssParameter name="stroke">#d9d9d9</CssParameter><CssParameter name="stroke-width">2.4</CssParameter></Stroke></LineSymbolizer>
        </Rule>
        <Rule>
          <Name>residential</Name>
          <MaxScaleDenominator>150000</MaxScaleDenominator>
          <ogc:Filter>
            <ogc:Or>
              <ogc:PropertyIsEqualTo><ogc:PropertyName>highway</ogc:PropertyName><ogc:Literal>residential</ogc:Literal></ogc:PropertyIsEqualTo>
              <ogc:PropertyIsEqualTo><ogc:PropertyName>highway</ogc:PropertyName><ogc:Literal>living_street</ogc:Literal></ogc:PropertyIsEqualTo>
            </ogc:Or>
          </ogc:Filter>
          <LineSymbolizer><Stroke><CssParameter name="stroke">#ffffff</CssParameter><CssParameter name="stroke-width">1.4</CssParameter></Stroke></LineSymbolizer>
        </Rule>
        <!-- service / unclassified / road -->
        <Rule>
          <Name>service-casing</Name>
          <MaxScaleDenominator>100000</MaxScaleDenominator>
          <ogc:Filter>
            <ogc:Or>
              <ogc:PropertyIsEqualTo><ogc:PropertyName>highway</ogc:PropertyName><ogc:Literal>service</ogc:Literal></ogc:PropertyIsEqualTo>
              <ogc:PropertyIsEqualTo><ogc:PropertyName>highway</ogc:PropertyName><ogc:Literal>unclassified</ogc:Literal></ogc:PropertyIsEqualTo>
              <ogc:PropertyIsEqualTo><ogc:PropertyName>highway</ogc:PropertyName><ogc:Literal>road</ogc:Literal></ogc:PropertyIsEqualTo>
            </ogc:Or>
          </ogc:Filter>
          <LineSymbolizer><Stroke><CssParameter name="stroke">#cfcfcf</CssParameter><CssParameter name="stroke-width">1.8</CssParameter></Stroke></LineSymbolizer>
        </Rule>
        <Rule>
          <Name>service</Name>
          <MaxScaleDenominator>100000</MaxScaleDenominator>
          <ogc:Filter>
            <ogc:Or>
              <ogc:PropertyIsEqualTo><ogc:PropertyName>highway</ogc:PropertyName><ogc:Literal>service</ogc:Literal></ogc:PropertyIsEqualTo>
              <ogc:PropertyIsEqualTo><ogc:PropertyName>highway</ogc:PropertyName><ogc:Literal>unclassified</ogc:Literal></ogc:PropertyIsEqualTo>
              <ogc:PropertyIsEqualTo><ogc:PropertyName>highway</ogc:PropertyName><ogc:Literal>road</ogc:Literal></ogc:PropertyIsEqualTo>
            </ogc:Or>
          </ogc:Filter>
          <LineSymbolizer><Stroke><CssParameter name="stroke">#f5f5f5</CssParameter><CssParameter name="stroke-width">1.1</CssParameter></Stroke></LineSymbolizer>
        </Rule>
        <!-- demais tipos OSM (ElseFilter) -->
        <Rule>
          <Name>other-roads</Name>
          <MaxScaleDenominator>40000</MaxScaleDenominator>
          <ElseFilter/>
          <LineSymbolizer><Stroke><CssParameter name="stroke">#cfcfcf</CssParameter><CssParameter name="stroke-width">0.8</CssParameter></Stroke></LineSymbolizer>
        </Rule>
      </FeatureTypeStyle>
    </UserStyle>
  </NamedLayer>
</StyledLayerDescriptor>
