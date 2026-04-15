<?xml version="1.0" encoding="UTF-8"?>
<StyledLayerDescriptor version="1.0.0"
  xsi:schemaLocation="http://www.opengis.net/sld StyledLayerDescriptor.xsd"
  xmlns="http://www.opengis.net/sld"
  xmlns:ogc="http://www.opengis.net/ogc"
  xmlns:xlink="http://www.w3.org/1999/xlink"
  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <NamedLayer>
    <Name>base_sp:municipios_alvo_sp</Name>
    <UserStyle>
      <Title>Municipios alvo destaque</Title>
      <FeatureTypeStyle>
        <Rule>
          <PolygonSymbolizer>
            <Fill>
              <CssParameter name="fill">#ffe08a</CssParameter>
              <CssParameter name="fill-opacity">0.23</CssParameter>
            </Fill>
            <Stroke>
              <CssParameter name="stroke">#d97706</CssParameter>
              <CssParameter name="stroke-width">0.8</CssParameter>
            </Stroke>
          </PolygonSymbolizer>
        </Rule>
        <!-- Regra separada apenas para os rótulos de município com limitação de zoom -->
        <Rule>
          <!-- Esconde os rótulos de município a escalas maiores (zoom in) -->
          <MinScaleDenominator>150000</MinScaleDenominator>
          <TextSymbolizer>
            <Geometry>
              <ogc:Function name="interiorPoint">
                <ogc:PropertyName>geom</ogc:PropertyName>
              </ogc:Function>
            </Geometry>
            <Label>
              <ogc:PropertyName>nm_mun</ogc:PropertyName>
            </Label>
            <Font>
              <CssParameter name="font-family">Arial</CssParameter>
              <CssParameter name="font-size">12</CssParameter>
              <CssParameter name="font-style">normal</CssParameter>
              <CssParameter name="font-weight">bold</CssParameter>
            </Font>
            <LabelPlacement>
              <PointPlacement>
                <AnchorPoint>
                  <AnchorPointX>0.5</AnchorPointX>
                  <AnchorPointY>0.5</AnchorPointY>
                </AnchorPoint>
              </PointPlacement>
            </LabelPlacement>
            <Halo>
              <Radius>1.2</Radius>
              <Fill><CssParameter name="fill">#ffffff</CssParameter></Fill>
            </Halo>
            <Fill><CssParameter name="fill">#7c2d12</CssParameter></Fill>
            <!-- Desliga o rótulo de município quando o zoom está muito próximo (evita sobreposição com os bairros) -->
            <VendorOption name="maxDisplacement">50</VendorOption>
            <VendorOption name="autoWrap">60</VendorOption>
            <VendorOption name="group">yes</VendorOption>
          </TextSymbolizer>
        </Rule>
      </FeatureTypeStyle>
    </UserStyle>
  </NamedLayer>
</StyledLayerDescriptor>
