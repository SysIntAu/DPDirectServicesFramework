package org.dpdirect.commons.xpath;

import java.util.HashMap;
import java.util.Iterator;

import javax.xml.namespace.NamespaceContext;

/**
 * An implementation of the <code>NamespaceContext</code> interface that uses
 * a HashMap of prefixes (keys) to namespace URIs (values) to resolve
 * <code>getNamespaceURI()</code> method calls.
 * 
 * @author N.A.
 * 
 */
public class NamespaceContextMap implements NamespaceContext {

	/**
	 * Map of namespace prefixes (keys) to namespace URIs (values).
	 */
	protected HashMap<String, String> namespaceBindings = null;

	/**
	 * Constructs a new <code>NamespaceContextMap</code> object using the
	 * default namespace bindings.
	 */
	public NamespaceContextMap() {
		this(null, true);
	}

	/**
	 * Constructs a new <code>NamespaceContextMap</code> object.
	 * 
	 * @param namespaceBindings
	 *            a map of namespace prefixes (keys) to namespace URIs (values).
	 * @param useDefaultBindings
	 *            indicates whether to use default namespace bindings in
	 *            addition to those provided.
	 */
	public NamespaceContextMap(HashMap<String, String> namespaceBindings,
			boolean useDefaultBindings) {
		this.namespaceBindings = namespaceBindings;
		if (null == this.namespaceBindings) {
			this.namespaceBindings = new HashMap<String, String>();
		}
		if (useDefaultBindings) {
			this.namespaceBindings
					.put("xs", "http://www.w3.org/2001/XMLSchema");
			this.namespaceBindings.put("xsd",
					"http://www.w3.org/2001/XMLSchema");
			this.namespaceBindings.put("xsi",
					"http://www.w3.org/2001/XMLSchema-instance");
			this.namespaceBindings.put("xsl",
					"http://www.w3.org/1999/XSL/Transform");
			this.namespaceBindings.put(
					AbstractXPathFunction.XPATH_FUNCTIONS_NS_PREFIX,
					AbstractXPathFunction.XPATH_FUNCTIONS_NS_URI);
		}
	}

	public String getNamespaceURI(String s) {
		if (null != namespaceBindings) {
			if (namespaceBindings.containsKey(s)) {
				return namespaceBindings.get(s);
			}
		}
		return null;
	}

	public String getPrefix(String s) {
		return null;
	}

	public Iterator<String> getPrefixes(String s) {
		return null;
	}
}
