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

      <!-- Rótulos: coluna name (OSM) existe em vias_alvo_sp; só linhas estavam estilizadas antes. -->
      <FeatureTypeStyle>
        <Rule>
          <Name>label-motorway-trunk</Name>
          <MaxScaleDenominator>2500000</MaxScaleDenominator>
          <ogc:Filter>
            <ogc:And>
              <ogc:Not><ogc:PropertyIsNull><ogc:PropertyName>name</ogc:PropertyName></ogc:PropertyIsNull></ogc:Not>
              <ogc:Not><ogc:PropertyIsEqualTo><ogc:PropertyName>name</ogc:PropertyName><ogc:Literal></ogc:Literal></ogc:PropertyIsEqualTo></ogc:Not>
              <ogc:Or>
                <ogc:PropertyIsEqualTo><ogc:PropertyName>highway</ogc:PropertyName><ogc:Literal>motorway</ogc:Literal></ogc:PropertyIsEqualTo>
                <ogc:PropertyIsEqualTo><ogc:PropertyName>highway</ogc:PropertyName><ogc:Literal>trunk</ogc:Literal></ogc:PropertyIsEqualTo>
              </ogc:Or>
            </ogc:And>
          </ogc:Filter>
          <TextSymbolizer>
            <Label><ogc:PropertyName>name</ogc:PropertyName></Label>
            <Font><CssParameter name="font-family">DejaVu Sans</CssParameter><CssParameter name="font-size">12</CssParameter></Font>
            <Fill><CssParameter name="fill">#3d3d3d</CssParameter></Fill>
            <Halo>
              <Radius><ogc:Literal>1.5</ogc:Literal></Radius>
              <Fill><CssParameter name="fill">#ffffff</CssParameter></Fill>
            </Halo>
            <LabelPlacement><LinePlacement/></LabelPlacement>
            <VendorOption name="followLine">true</VendorOption>
            <VendorOption name="repeat">220</VendorOption>
            <VendorOption name="maxAngleDelta">55</VendorOption>
          </TextSymbolizer>
        </Rule>
        <Rule>
          <Name>label-primary</Name>
          <MaxScaleDenominator>900000</MaxScaleDenominator>
          <ogc:Filter>
            <ogc:And>
              <ogc:Not><ogc:PropertyIsNull><ogc:PropertyName>name</ogc:PropertyName></ogc:PropertyIsNull></ogc:Not>
              <ogc:Not><ogc:PropertyIsEqualTo><ogc:PropertyName>name</ogc:PropertyName><ogc:Literal></ogc:Literal></ogc:PropertyIsEqualTo></ogc:Not>
              <ogc:PropertyIsEqualTo><ogc:PropertyName>highway</ogc:PropertyName><ogc:Literal>primary</ogc:Literal></ogc:PropertyIsEqualTo>
            </ogc:And>
          </ogc:Filter>
          <TextSymbolizer>
            <Label><ogc:PropertyName>name</ogc:PropertyName></Label>
            <Font><CssParameter name="font-family">DejaVu Sans</CssParameter><CssParameter name="font-size">11</CssParameter></Font>
            <Fill><CssParameter name="fill">#404040</CssParameter></Fill>
            <Halo>
              <Radius><ogc:Literal>1.5</ogc:Literal></Radius>
              <Fill><CssParameter name="fill">#ffffff</CssParameter></Fill>
            </Halo>
            <LabelPlacement><LinePlacement/></LabelPlacement>
            <VendorOption name="followLine">true</VendorOption>
            <VendorOption name="repeat">200</VendorOption>
            <VendorOption name="maxAngleDelta">55</VendorOption>
          </TextSymbolizer>
        </Rule>
        <Rule>
          <Name>label-secondary</Name>
          <MaxScaleDenominator>350000</MaxScaleDenominator>
          <ogc:Filter>
            <ogc:And>
              <ogc:Not><ogc:PropertyIsNull><ogc:PropertyName>name</ogc:PropertyName></ogc:PropertyIsNull></ogc:Not>
              <ogc:Not><ogc:PropertyIsEqualTo><ogc:PropertyName>name</ogc:PropertyName><ogc:Literal></ogc:Literal></ogc:PropertyIsEqualTo></ogc:Not>
              <ogc:PropertyIsEqualTo><ogc:PropertyName>highway</ogc:PropertyName><ogc:Literal>secondary</ogc:Literal></ogc:PropertyIsEqualTo>
            </ogc:And>
          </ogc:Filter>
          <TextSymbolizer>
            <Label><ogc:PropertyName>name</ogc:PropertyName></Label>
            <Font><CssParameter name="font-family">DejaVu Sans</CssParameter><CssParameter name="font-size">10</CssParameter></Font>
            <Fill><CssParameter name="fill">#454545</CssParameter></Fill>
            <Halo>
              <Radius><ogc:Literal>1.3</ogc:Literal></Radius>
              <Fill><CssParameter name="fill">#ffffff</CssParameter></Fill>
            </Halo>
            <LabelPlacement><LinePlacement/></LabelPlacement>
            <VendorOption name="followLine">true</VendorOption>
            <VendorOption name="repeat">160</VendorOption>
            <VendorOption name="maxAngleDelta">55</VendorOption>
          </TextSymbolizer>
        </Rule>
        <Rule>
          <Name>label-tertiary</Name>
          <MaxScaleDenominator>130000</MaxScaleDenominator>
          <ogc:Filter>
            <ogc:And>
              <ogc:Not><ogc:PropertyIsNull><ogc:PropertyName>name</ogc:PropertyName></ogc:PropertyIsNull></ogc:Not>
              <ogc:Not><ogc:PropertyIsEqualTo><ogc:PropertyName>name</ogc:PropertyName><ogc:Literal></ogc:Literal></ogc:PropertyIsEqualTo></ogc:Not>
              <ogc:PropertyIsEqualTo><ogc:PropertyName>highway</ogc:PropertyName><ogc:Literal>tertiary</ogc:Literal></ogc:PropertyIsEqualTo>
            </ogc:And>
          </ogc:Filter>
          <TextSymbolizer>
            <Label><ogc:PropertyName>name</ogc:PropertyName></Label>
            <Font><CssParameter name="font-family">DejaVu Sans</CssParameter><CssParameter name="font-size">10</CssParameter></Font>
            <Fill><CssParameter name="fill">#4a4a4a</CssParameter></Fill>
            <Halo>
              <Radius><ogc:Literal>1.2</ogc:Literal></Radius>
              <Fill><CssParameter name="fill">#ffffff</CssParameter></Fill>
            </Halo>
            <LabelPlacement><LinePlacement/></LabelPlacement>
            <VendorOption name="followLine">true</VendorOption>
            <VendorOption name="repeat">140</VendorOption>
            <VendorOption name="maxAngleDelta">50</VendorOption>
          </TextSymbolizer>
        </Rule>
        <Rule>
          <Name>label-residential</Name>
          <MaxScaleDenominator>85000</MaxScaleDenominator>
          <ogc:Filter>
            <ogc:And>
              <ogc:Not><ogc:PropertyIsNull><ogc:PropertyName>name</ogc:PropertyName></ogc:PropertyIsNull></ogc:Not>
              <ogc:Not><ogc:PropertyIsEqualTo><ogc:PropertyName>name</ogc:PropertyName><ogc:Literal></ogc:Literal></ogc:PropertyIsEqualTo></ogc:Not>
              <ogc:Or>
                <ogc:PropertyIsEqualTo><ogc:PropertyName>highway</ogc:PropertyName><ogc:Literal>residential</ogc:Literal></ogc:PropertyIsEqualTo>
                <ogc:PropertyIsEqualTo><ogc:PropertyName>highway</ogc:PropertyName><ogc:Literal>living_street</ogc:Literal></ogc:PropertyIsEqualTo>
              </ogc:Or>
            </ogc:And>
          </ogc:Filter>
          <TextSymbolizer>
            <Label><ogc:PropertyName>name</ogc:PropertyName></Label>
            <Font><CssParameter name="font-family">DejaVu Sans</CssParameter><CssParameter name="font-size">9</CssParameter></Font>
            <Fill><CssParameter name="fill">#505050</CssParameter></Fill>
            <Halo>
              <Radius><ogc:Literal>1.2</ogc:Literal></Radius>
              <Fill><CssParameter name="fill">#ffffff</CssParameter></Fill>
            </Halo>
            <LabelPlacement><LinePlacement/></LabelPlacement>
            <VendorOption name="followLine">true</VendorOption>
            <VendorOption name="repeat">120</VendorOption>
            <VendorOption name="maxAngleDelta">45</VendorOption>
          </TextSymbolizer>
        </Rule>
        <Rule>
          <Name>label-service</Name>
          <MaxScaleDenominator>65000</MaxScaleDenominator>
          <ogc:Filter>
            <ogc:And>
              <ogc:Not><ogc:PropertyIsNull><ogc:PropertyName>name</ogc:PropertyName></ogc:PropertyIsNull></ogc:Not>
              <ogc:Not><ogc:PropertyIsEqualTo><ogc:PropertyName>name</ogc:PropertyName><ogc:Literal></ogc:Literal></ogc:PropertyIsEqualTo></ogc:Not>
              <ogc:Or>
                <ogc:PropertyIsEqualTo><ogc:PropertyName>highway</ogc:PropertyName><ogc:Literal>service</ogc:Literal></ogc:PropertyIsEqualTo>
                <ogc:PropertyIsEqualTo><ogc:PropertyName>highway</ogc:PropertyName><ogc:Literal>unclassified</ogc:Literal></ogc:PropertyIsEqualTo>
                <ogc:PropertyIsEqualTo><ogc:PropertyName>highway</ogc:PropertyName><ogc:Literal>road</ogc:Literal></ogc:PropertyIsEqualTo>
              </ogc:Or>
            </ogc:And>
          </ogc:Filter>
          <TextSymbolizer>
            <Label><ogc:PropertyName>name</ogc:PropertyName></Label>
            <Font><CssParameter name="font-family">DejaVu Sans</CssParameter><CssParameter name="font-size">9</CssParameter></Font>
            <Fill><CssParameter name="fill">#555555</CssParameter></Fill>
            <Halo>
              <Radius><ogc:Literal>1.1</ogc:Literal></Radius>
              <Fill><CssParameter name="fill">#ffffff</CssParameter></Fill>
            </Halo>
            <LabelPlacement><LinePlacement/></LabelPlacement>
            <VendorOption name="followLine">true</VendorOption>
            <VendorOption name="repeat">100</VendorOption>
            <VendorOption name="maxAngleDelta">45</VendorOption>
          </TextSymbolizer>
        </Rule>
        <Rule>
          <Name>label-other</Name>
          <MaxScaleDenominator>32000</MaxScaleDenominator>
          <ogc:Filter>
            <ogc:And>
              <ogc:Not><ogc:PropertyIsNull><ogc:PropertyName>name</ogc:PropertyName></ogc:PropertyIsNull></ogc:Not>
              <ogc:Not><ogc:PropertyIsEqualTo><ogc:PropertyName>name</ogc:PropertyName><ogc:Literal></ogc:Literal></ogc:PropertyIsEqualTo></ogc:Not>
            </ogc:And>
          </ogc:Filter>
          <TextSymbolizer>
            <Label><ogc:PropertyName>name</ogc:PropertyName></Label>
            <Font><CssParameter name="font-family">DejaVu Sans</CssParameter><CssParameter name="font-size">8</CssParameter></Font>
            <Fill><CssParameter name="fill">#5a5a5a</CssParameter></Fill>
            <Halo>
              <Radius><ogc:Literal>1</ogc:Literal></Radius>
              <Fill><CssParameter name="fill">#ffffff</CssParameter></Fill>
            </Halo>
            <LabelPlacement><LinePlacement/></LabelPlacement>
            <VendorOption name="followLine">true</VendorOption>
            <VendorOption name="repeat">90</VendorOption>
            <VendorOption name="maxAngleDelta">40</VendorOption>
          </TextSymbolizer>
        </Rule>
      </FeatureTypeStyle>
    </UserStyle>
  </NamedLayer>
</StyledLayerDescriptor>
