<?xml version="1.0" encoding="UTF-8"?>
<StyledLayerDescriptor version="1.0.0"
  xsi:schemaLocation="http://www.opengis.net/sld StyledLayerDescriptor.xsd"
  xmlns="http://www.opengis.net/sld"
  xmlns:ogc="http://www.opengis.net/ogc"
  xmlns:xlink="http://www.w3.org/1999/xlink"
  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <NamedLayer>
    <Name>base_sp:bairros_alvo_sp</Name>
    <UserStyle>
      <Title>Bairros alvo</Title>
      <FeatureTypeStyle>
        <Rule>
          <MaxScaleDenominator>400000</MaxScaleDenominator>
          <PolygonSymbolizer>
            <Fill>
              <CssParameter name="fill">#94a3b8</CssParameter>
              <CssParameter name="fill-opacity">0.045</CssParameter>
            </Fill>
            <Stroke>
              <CssParameter name="stroke">#64748b</CssParameter>
              <CssParameter name="stroke-opacity">0.55</CssParameter>
              <CssParameter name="stroke-width">0.45</CssParameter>
            </Stroke>
          </PolygonSymbolizer>
          <TextSymbolizer>
            <Geometry>
              <ogc:Function name="interiorPoint">
                <ogc:PropertyName>geom</ogc:PropertyName>
              </ogc:Function>
            </Geometry>
            <Label>
              <ogc:PropertyName>municipio_nome</ogc:PropertyName><![CDATA[
]]><ogc:PropertyName>bairro_nome</ogc:PropertyName>
            </Label>
            <Font>
              <CssParameter name="font-family">Arial</CssParameter>
              <CssParameter name="font-size">9</CssParameter>
              <CssParameter name="font-style">normal</CssParameter>
              <CssParameter name="font-weight">normal</CssParameter>
            </Font>
            <Halo>
              <Radius>1</Radius>
              <Fill><CssParameter name="fill">#ffffff</CssParameter><CssParameter name="fill-opacity">0.85</CssParameter></Fill>
            </Halo>
            <Fill><CssParameter name="fill">#475569</CssParameter></Fill>
            <!-- group=yes agrupa polígonos com o mesmo nome e exibe apenas 1 rótulo central -->
            <!-- goodnessOfFit diminui a restrição de caber o texto perfeitamente no polígono, útil para geometrias fragmentadas -->
            <VendorOption name="group">yes</VendorOption>
            <VendorOption name="goodnessOfFit">0.3</VendorOption>
            <VendorOption name="autoWrap">60</VendorOption>
          </TextSymbolizer>
        </Rule>
      </FeatureTypeStyle>
    </UserStyle>
  </NamedLayer>
</StyledLayerDescriptor>
