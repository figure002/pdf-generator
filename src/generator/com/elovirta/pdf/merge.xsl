<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:map="http://www.w3.org/2005/xpath-functions/map"
  xmlns:array="http://www.w3.org/2005/xpath-functions/array" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:x="x"
  exclude-result-prefixes="xs x" version="3.0">

  <xsl:output method="json"/>

  <xsl:param name="base-url"/>

  <xsl:variable name="separator" select="'-'"/>

  <xsl:template match=".[. instance of map(*)]">
    <xsl:sequence select="x:extends(., $base-url)"/>
  </xsl:template>
  
  <xsl:function name="x:extends" as="item()*">
    <xsl:param name="base" as="item()*"/>
    <xsl:param name="url"/>
    <xsl:choose>
      <xsl:when test="map:contains($base, 'extends')">
        <xsl:variable name="extends-url" select="resolve-uri($base ?extends, $url)"/>
        <xsl:variable name="extends" select="x:extends(json-doc($extends-url), $extends-url)"/>
<!--        <xsl:sequence select="x:merge($extends, x:flatten(x:normalize($base, (), $extends-url)))"/>-->
        <xsl:sequence select="map:merge((x:normalize(x:flatten($base), (), $extends-url), $extends),
                                        map{ 'duplicates': 'use-first' })"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:sequence select="x:normalize(x:flatten($base), (), $url)"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <xsl:function name="x:flatten" as="item()*" visibility="public">
    <xsl:param name="root" as="item()"/>
    <xsl:variable name="flattened" as="map(*)">
      <xsl:map>
        <xsl:sequence select="x:flatten-walker($root, $root, ())"/>
      </xsl:map>
    </xsl:variable>
    <xsl:sequence select="map:merge(($flattened), map{ 'duplicates': 'use-first' })"/>
  </xsl:function>

  <xsl:function name="x:flatten-walker" as="item()*">
    <xsl:param name="root" as="map(*)"/>
    <xsl:param name="base" as="map(*)"/>
    <xsl:param name="ancestors" as="item()*"/>

    <xsl:for-each select="map:keys($base)">
      <xsl:variable name="key" select="."/>
      <xsl:variable name="value" select="map:get($base, $key)"/>
      <xsl:choose>
        <xsl:when test="$value instance of map(*)">
          <xsl:sequence select="x:flatten-walker($root, $value, ($ancestors, $key))"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:variable name="flattened-name" select="string-join(($ancestors, $key), $separator) => x:rewrite-key-name()"/>
          <xsl:if test="not(map:contains($root, $flattened-name))">
            <xsl:map-entry key="$flattened-name" select="$value"/>
          </xsl:if>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:for-each>
  </xsl:function>

  <xsl:function name="x:rewrite-key-name" as="xs:string">
    <xsl:param name="key" as="xs:string"/>
    <xsl:value-of select="replace($key, '_', '-')
                       => replace('-(space|border|padding)-top', '-$1-before')
                       => replace('-(space|border|padding)-right', '-$1-end')
                       => replace('-(space|border|padding)-bottom', '-$1-after')
                       => replace('-(space|border|padding)-left', '-$1-start')"/>
  </xsl:function>

  <xsl:function name="x:merge" as="item()*" visibility="public">
    <xsl:param name="base" as="item()*"/>
    <xsl:param name="theme" as="item()*"/>
    <xsl:choose>
      <xsl:when test="empty($base)">
        <xsl:sequence select="$theme"/>
      </xsl:when>
      <xsl:when test="empty($theme)">
        <xsl:sequence select="$base"/>
      </xsl:when>
      <xsl:when test="$base instance of array(*) or $theme instance of array(*)">
        <xsl:sequence select="
            if (exists($theme)) then
              $theme
            else
              $base"/>
      </xsl:when>
      <xsl:when test="$base instance of map(*) or $theme instance of map(*)">
        <xsl:map>
          <xsl:variable name="all-keys" select="distinct-values((map:keys($base), map:keys($theme)))"/>
          <xsl:for-each select="$all-keys">
            <xsl:map-entry key="." select="x:merge(map:get($base, .), map:get($theme, .))"/>
          </xsl:for-each>
        </xsl:map>
      </xsl:when>
      <xsl:otherwise>
        <xsl:sequence select="
            if (exists($theme)) then
              $theme
            else
              $base"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <xsl:function name="x:normalize" as="item()*" visibility="public">
    <xsl:param name="base" as="item()*"/>
    <xsl:param name="ancestors" as="item()*"/>
    <xsl:param name="url" as="item()"/>
    <xsl:choose>
      <xsl:when test="$base instance of array(*)">
        <xsl:variable name="array" as="map(*)*">
          <xsl:for-each select="1 to array:size($base)">
            <xsl:variable name="index" select="."/>
            <xsl:variable name="value" select="array:get($base, $index)"/>
            <xsl:sequence select="x:normalize($value, $ancestors, $url)"/>
          </xsl:for-each>
        </xsl:variable>
        <xsl:sequence select="array{ $array }"/>
      </xsl:when>
      <xsl:when test="$base instance of map(*)">
        <xsl:map>
<!--          <xsl:if test="empty($ancestors) and not(map:contains($base, 'style'))">-->
<!--            <xsl:map-entry key="'style'" select="map{}"/>-->
<!--          </xsl:if>-->
          <xsl:for-each select="map:keys($base)">
            <xsl:variable name="key" select="."/>
            <xsl:variable name="value" select="map:get($base, $key)"/>
            <xsl:choose>
              <!-- Parse content DSL into AST -->
              <xsl:when test="matches($key, '-content$') and not($value instance of array(*))">
                <xsl:variable name="tokens" as="item()*">
                  <xsl:analyze-string select="$value" regex="\{{(.+?)\}}">
                    <xsl:matching-substring>
                      <xsl:choose>
                        <xsl:when test="starts-with(regex-group(1), '#')">
                          <xsl:sequence select="map{ 'kind': 'variable', 'value': substring(regex-group(1), 2) }"/>
                        </xsl:when>
                        <xsl:otherwise>
                          <xsl:sequence select="map{ 'kind': 'field', 'value': regex-group(1) }"/>
                        </xsl:otherwise>
                      </xsl:choose>
                    </xsl:matching-substring>
                    <xsl:non-matching-substring>
                      <xsl:sequence select="map{ 'kind': 'text', 'value': .}"/>
                    </xsl:non-matching-substring>
                  </xsl:analyze-string>
                </xsl:variable>
                <xsl:map-entry key="$key" select="array{ $tokens }"/>
              </xsl:when>
              <!-- Map page size and orientation into page dimensions -->
              <xsl:when test="$key = 'page-size' and empty($ancestors)">
                <xsl:variable name="sizes" select="map:get($page-sizes, $value)" as="array(*)?"/>
                <xsl:choose>
                  <xsl:when test="exists($sizes)">
                    <xsl:choose>
                      <xsl:when test="$base ?page-orientation = 'landscape'">
                        <xsl:map-entry key="'page-height'" select="array:get($sizes, 1)"/>
                        <xsl:map-entry key="'page-width'" select="array:get($sizes, 2)"/>
                      </xsl:when>
                      <xsl:otherwise>
                        <xsl:map-entry key="'page-height'" select="array:get($sizes, 2)"/>
                        <xsl:map-entry key="'page-width'" select="array:get($sizes, 1)"/>
                      </xsl:otherwise>
                    </xsl:choose>
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:message terminate="yes" expand-text="yes">ERROR: Page size '{$value}' not supported.</xsl:message>
                  </xsl:otherwise>
                </xsl:choose>
              </xsl:when>
              <xsl:when test="$key = 'page-orientation' and empty($ancestors)"/>
              <!-- Convert image reference to FO format -->
              <xsl:when test="matches($key, '[\-\^]background-image$')">
                <xsl:variable name="image-url">
                  <xsl:analyze-string select="$value" regex="url\([&quot;'](.+?)[&quot;']\)">
                    <xsl:matching-substring>
                      <xsl:value-of select="regex-group(1)"/>
                    </xsl:matching-substring>
                    <xsl:non-matching-substring>
                      <xsl:value-of select="$value"/>
                    </xsl:non-matching-substring>
                  </xsl:analyze-string>
                </xsl:variable>
                <xsl:map-entry key="$key">
                  <xsl:value-of>
                    <xsl:text>url('</xsl:text>
                    <xsl:value-of select="resolve-uri($image-url, $url)"/>
                    <xsl:text>')</xsl:text>
                  </xsl:value-of>
                </xsl:map-entry>                    
              </xsl:when>
              <!-- Expand border shorthand -->
              <xsl:when test="$key = 'border'">
                <xsl:variable name="tokens" select="x:parse-border($value)" as="map(*)"/>
                <xsl:for-each select="('before', 'end', 'after', 'start')">
                  <xsl:map-entry key="concat('border-', ., '-style')" select="$tokens ?style"/>
                  <xsl:map-entry key="concat('border-', ., '-width')" select="$tokens ?width"/>
                  <xsl:map-entry key="concat('border-', ., '-color')" select="$tokens ?color"/>                  
                </xsl:for-each>
              </xsl:when>
              <xsl:when test="matches($key, '^border-(top|right|bottom|left|before|end|after|start)$')">
                <xsl:variable name="tokens" select="x:parse-border($value)" as="map(*)"/>
                <xsl:variable name="direction">
                  <xsl:choose>
                    <xsl:when test="$key = ('border-top', 'border-before')">before</xsl:when>
                    <xsl:when test="$key = ('border-right', 'border-end')">end</xsl:when>
                    <xsl:when test="$key = ('border-bottom', 'border-after')">after</xsl:when>
                    <xsl:when test="$key = ('border-left', 'border-start')">start</xsl:when>
                  </xsl:choose>
                </xsl:variable>
                <xsl:map-entry key="concat('border-', $direction, '-style')" select="$tokens ?style"/>
                <xsl:map-entry key="concat('border-', $direction, '-width')" select="$tokens ?width"/>
                <xsl:map-entry key="concat('border-', $direction, '-color')" select="$tokens ?color"/>                  
              </xsl:when>
              <xsl:when test="matches($key, '^border-(style|width|color)$')">
                <xsl:variable name="type" select="substring-after($key, '-')"/>
                <xsl:for-each select="('before', 'end', 'after', 'start')">
                  <xsl:map-entry key="concat('border-', ., '-', $type)" select="$value"/>
                </xsl:for-each>
              </xsl:when>
              <xsl:when test="matches($key, '^.+?-(top|right|bottom|left)(-.+?)?$')">
                <xsl:variable name="name">
                  <xsl:analyze-string select="$key" regex="^(.+?-)(top|right|bottom|left)(-.+?)?$">
                    <xsl:matching-substring>
                      <xsl:value-of>
                        <xsl:value-of select="regex-group(1)"/>
                        <xsl:choose>
                          <xsl:when test="regex-group(2) = 'top'">before</xsl:when>
                          <xsl:when test="regex-group(2) = 'right'">end</xsl:when>
                          <xsl:when test="regex-group(2) = 'bottom'">after</xsl:when>
                          <xsl:when test="regex-group(2) = 'left'">start</xsl:when>
                        </xsl:choose>
                        <xsl:value-of select="regex-group(3)"/>
                      </xsl:value-of>
                    </xsl:matching-substring>
                  </xsl:analyze-string>
                </xsl:variable>
                <xsl:map-entry key="$name" select="$value"/>
              </xsl:when>
              <!-- Group header and footer styles under odd and even -->
              <xsl:when test="$key = ('header', 'footer') and empty($ancestors) and exists(($value ?odd, $value ?even))">
                <xsl:variable name="other" select="x:exclude($value, ('odd', 'even'))" as="map(*)"/>
                <xsl:map-entry key="$key" select="
                  map {
                   'odd': x:normalize(map:merge(($value ?odd, $other)), ($ancestors, $key, 'odd'), $url),
                   'even': x:normalize(map:merge(($value ?even, $other)), ($ancestors, $key, 'even'), $url)
                  }"/>
              </xsl:when>
              <xsl:when test="$key = ('header', 'footer') and empty($ancestors) and empty(($value ?odd, $value ?even))">
                <xsl:map-entry key="$key" select="
                  map {
                    'odd': x:normalize($value, ($ancestors, $key, 'odd'), $url),
                    'even': x:normalize($value, ($ancestors, $key, 'even'), $url)
                  }"/>
              </xsl:when>
              <!-- Rewrite h1-h4 to topic(-topic){0,3} -->
              <xsl:when test="matches($key, '-h1-')">
                <xsl:map-entry key="replace($key, '-h1-', '-topic-')" select="x:normalize($value, ($ancestors, $key), $url)"/>
              </xsl:when>
              <xsl:when test="matches($key, '-h2-')">
                <xsl:map-entry key="replace($key, '-h2-', '-topic-topic-')" select="x:normalize($value, ($ancestors, $key), $url)"/>
              </xsl:when>
              <xsl:when test="matches($key, '-h3-')">
                <xsl:map-entry key="replace($key, '-h3-', '-topic-topic-topic-')" select="x:normalize($value, ($ancestors, $key), $url)"/>
              </xsl:when>
              <xsl:when test="matches($key, '-h4-')">
                <xsl:map-entry key="replace($key, '-h4-', '-topic-topic-topic-topic-')" select="x:normalize($value, ($ancestors, $key), $url)"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:map-entry key="replace($key, '_', '-')" select="x:normalize($value, ($ancestors, $key), $url)"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:for-each>
        </xsl:map>
      </xsl:when>
      <xsl:otherwise>
        <xsl:sequence select="$base"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>
  
  <xsl:function name="x:exclude">
    <xsl:param name="map" as="map(*)"/>
    <xsl:param name="names" as="item()*"/>
    <xsl:map>
      <xsl:for-each select="map:keys($map)">
        <xsl:if test="not(. = $names)">
          <xsl:map-entry key="." select="map:get($map, .)"/>
        </xsl:if>
      </xsl:for-each>
    </xsl:map>
  </xsl:function>
  
  <xsl:function name="x:parse-border" as="map(*)">
    <xsl:param name="value" as="item()"/>
    <xsl:map>
      <xsl:for-each select="tokenize(normalize-space($value), '\s+')">
        <xsl:choose>
          <xsl:when test="matches(., '^(none|hidden|dotted|dashed|solid|double|groove|ridge|inset|outset|inherit)$')">
            <xsl:map-entry key="'style'" select="."/>
          </xsl:when>
          <xsl:when test="matches(., '(cm|mm|in|pt|pc|px|em)$')">
            <xsl:map-entry key="'width'" select="."/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:map-entry key="'color'" select="."/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:for-each>                    
    </xsl:map>
  </xsl:function>

  <xsl:variable name="page-sizes" as="map(*)" select="map{
    'A3': ['297mm', '420mm'],
    'A4': ['210mm', '297mm'],
    'A5': ['148mm', '210mm'],
    'Executive': ['184.1mm', '266.7mm'],
    'JIS B5': ['182mm', '257mm'],
    'Tabloid': ['431.8mm', '279.4mm'],
    'Legal': ['8.5in', '14in'],
    'Letter': ['8.5in', '11in'],
    'PA4': ['210mm', '280mm'] 
    }"/>
  

  <xsl:function name="x:resolve" as="map(*)" visibility="public">
    <xsl:param name="base" as="map(*)"/>
    <xsl:variable name="keys" select="x:flatten($base, ())" as="map(*)"/>
    <xsl:sequence select="x:resolveVariables($base, $keys)"/>
  </xsl:function>
  
  <xsl:function name="x:flatten" as="map(*)">
    <xsl:param name="base" as="item()"/>
    <xsl:param name="ancestors" as="item()*"/>
    <xsl:choose>
      <xsl:when test="$base instance of array(*)">
       <xsl:map/>
      </xsl:when>
      <xsl:when test="$base instance of map(*)">
        <xsl:variable name="maps" as="map(*)*">
          <xsl:for-each select="map:keys($base)">
            <xsl:variable name="key" select="."/>
            <xsl:variable name="value" select="map:get($base, $key)"/>
            <xsl:sequence select="x:flatten($value, ($ancestors, $key))"/>
          </xsl:for-each>
        </xsl:variable>
        <xsl:sequence select="map:merge($maps)"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:map>
          <xsl:map-entry key="string-join($ancestors, $separator)" select="$base"/>
        </xsl:map>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <!-- Resolve variables in flattened theme -->
  <xsl:function name="x:resolveVariables" as="item()">
    <xsl:param name="base" as="map(*)"/>
    <xsl:param name="keys" as="map(*)"/>

    <xsl:map>
      <xsl:for-each select="map:keys($base)">
        <xsl:variable name="key" select="."/>
        <xsl:variable name="value" as="item()">
          <xsl:variable name="v" select="map:get($base, $key)"/>
          <xsl:choose>
            <xsl:when test="$v instance of array(*) or $v instance of map(*)">
              <xsl:sequence select="$v"/>
            </xsl:when>
            <xsl:when test="starts-with(string($v), '$')">
              <xsl:variable name="variable" select="substring(string($v), 2)"/>
              <xsl:choose>
                <xsl:when test="map:contains($keys, $variable)">
                  <xsl:sequence select="map:get($keys, $variable)"/>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:message>[ERROR] No binding for variable <xsl:value-of select="$variable"/> found</xsl:message>
                  <xsl:sequence select="$v"/>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
              <xsl:sequence select="$v"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
<!--            <xsl:map-entry key="$key" select="x:resolveVariables($value, $keys)"/>-->
        <xsl:map-entry key="$key" select="$value"/>
      </xsl:for-each>
    </xsl:map>
  </xsl:function>

</xsl:stylesheet>
