<?xml version="1.0" encoding="UTF-8"?>
<StyledLayerDescriptor version="1.0.0"
  xsi:schemaLocation="http://www.opengis.net/sld StyledLayerDescriptor.xsd"
  xmlns="http://www.opengis.net/sld"
  xmlns:ogc="http://www.opengis.net/ogc"
  xmlns:xlink="http://www.w3.org/1999/xlink"
  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <NamedLayer>
    <Name>base_sp:vias_centro_sp</Name>
    <UserStyle>
      <Title>Base SP Roads Google-like</Title>
      <FeatureTypeStyle>
        <Rule>
          <Name>motorway-trunk-casing</Name>
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
          <ogc:Filter>
            <ogc:Or>
              <ogc:PropertyIsEqualTo><ogc:PropertyName>highway</ogc:PropertyName><ogc:Literal>motorway</ogc:Literal></ogc:PropertyIsEqualTo>
              <ogc:PropertyIsEqualTo><ogc:PropertyName>highway</ogc:PropertyName><ogc:Literal>trunk</ogc:Literal></ogc:PropertyIsEqualTo>
            </ogc:Or>
          </ogc:Filter>
          <LineSymbolizer><Stroke><CssParameter name="stroke">#f7d88f</CssParameter><CssParameter name="stroke-width">3.6</CssParameter></Stroke></LineSymbolizer>
        </Rule>
        <Rule>
          <Name>primary-secondary-casing</Name>
          <ogc:Filter>
            <ogc:Or>
              <ogc:PropertyIsEqualTo><ogc:PropertyName>highway</ogc:PropertyName><ogc:Literal>primary</ogc:Literal></ogc:PropertyIsEqualTo>
              <ogc:PropertyIsEqualTo><ogc:PropertyName>highway</ogc:PropertyName><ogc:Literal>secondary</ogc:Literal></ogc:PropertyIsEqualTo>
            </ogc:Or>
          </ogc:Filter>
          <LineSymbolizer><Stroke><CssParameter name="stroke">#f6e2b2</CssParameter><CssParameter name="stroke-width">4.0</CssParameter></Stroke></LineSymbolizer>
        </Rule>
        <Rule>
          <Name>primary-secondary</Name>
          <ogc:Filter>
            <ogc:Or>
              <ogc:PropertyIsEqualTo><ogc:PropertyName>highway</ogc:PropertyName><ogc:Literal>primary</ogc:Literal></ogc:PropertyIsEqualTo>
              <ogc:PropertyIsEqualTo><ogc:PropertyName>highway</ogc:PropertyName><ogc:Literal>secondary</ogc:Literal></ogc:PropertyIsEqualTo>
            </ogc:Or>
          </ogc:Filter>
          <LineSymbolizer><Stroke><CssParameter name="stroke">#ffffff</CssParameter><CssParameter name="stroke-width">2.4</CssParameter></Stroke></LineSymbolizer>
        </Rule>
        <Rule>
          <Name>tertiary-residential-casing</Name>
          <ogc:Filter>
            <ogc:Or>
              <ogc:PropertyIsEqualTo><ogc:PropertyName>highway</ogc:PropertyName><ogc:Literal>tertiary</ogc:Literal></ogc:PropertyIsEqualTo>
              <ogc:PropertyIsEqualTo><ogc:PropertyName>highway</ogc:PropertyName><ogc:Literal>residential</ogc:Literal></ogc:PropertyIsEqualTo>
              <ogc:PropertyIsEqualTo><ogc:PropertyName>highway</ogc:PropertyName><ogc:Literal>living_street</ogc:Literal></ogc:PropertyIsEqualTo>
            </ogc:Or>
          </ogc:Filter>
          <LineSymbolizer><Stroke><CssParameter name="stroke">#d9d9d9</CssParameter><CssParameter name="stroke-width">2.7</CssParameter></Stroke></LineSymbolizer>
        </Rule>
        <Rule>
          <Name>tertiary-residential</Name>
          <ogc:Filter>
            <ogc:Or>
              <ogc:PropertyIsEqualTo><ogc:PropertyName>highway</ogc:PropertyName><ogc:Literal>tertiary</ogc:Literal></ogc:PropertyIsEqualTo>
              <ogc:PropertyIsEqualTo><ogc:PropertyName>highway</ogc:PropertyName><ogc:Literal>residential</ogc:Literal></ogc:PropertyIsEqualTo>
              <ogc:PropertyIsEqualTo><ogc:PropertyName>highway</ogc:PropertyName><ogc:Literal>living_street</ogc:Literal></ogc:PropertyIsEqualTo>
            </ogc:Or>
          </ogc:Filter>
          <LineSymbolizer><Stroke><CssParameter name="stroke">#ffffff</CssParameter><CssParameter name="stroke-width">1.7</CssParameter></Stroke></LineSymbolizer>
        </Rule>
        <Rule>
          <Name>other-roads</Name>
          <ElseFilter/>
          <LineSymbolizer><Stroke><CssParameter name="stroke">#cfcfcf</CssParameter><CssParameter name="stroke-width">0.8</CssParameter></Stroke></LineSymbolizer>
        </Rule>
      </FeatureTypeStyle>
    </UserStyle>
  </NamedLayer>
</StyledLayerDescriptor>
