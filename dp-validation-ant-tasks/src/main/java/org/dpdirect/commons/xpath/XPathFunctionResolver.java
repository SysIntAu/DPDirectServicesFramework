package org.dpdirect.commons.xpath;

import java.util.HashMap;
import java.util.Iterator;

import javax.xml.namespace.QName;
import javax.xml.xpath.XPathFunction;
import javax.xml.xpath.XPathFunctionResolver;

import org.dpdirect.commons.xpath.func.IsLowerCamelCaseFunction;
import org.dpdirect.commons.xpath.func.IsUpperCamelCaseFunction;

/**
 * A custom XPath function resolver which handles the
 * <code>resolveFunction()</code> method calls to custom DPDIRECT XPath functions.
 * 
 * @author N.A.
 */
public class XPathFunctionResolver implements javax.xml.xpath.XPathFunctionResolver {

	/**
	 * Singleton class instance.
	 */
	private static XPathFunctionResolver instance = null;

	/**
	 * Collection of functions.
	 */
	private HashMap<String, AbstractXPathFunction> functionMap = null;

	/**
	 * Private constructor for instantiating singleton instance.
	 */
	private XPathFunctionResolver() {
		// Add all known DPDIRECT XPath functions
		if (null == functionMap) {
			functionMap = new HashMap<String, AbstractXPathFunction>();
		}
		addFunction(IsLowerCamelCaseFunction.getInstance());
		addFunction(IsUpperCamelCaseFunction.getInstance());
	}

	/**
	 * Gets the class instance.
	 * 
	 * @return the shared class instance.
	 */
	public static XPathFunctionResolver getInstance() {
		if (null == instance) {
			instance = new XPathFunctionResolver();
		}
		return instance;
	}

	/**
	 * Implementatin of the XPathFunctionResolver interface method to resolve a
	 * function based on its QName and number of arguments.
	 * 
	 * @param qName
	 *            the QName of the function.
	 * @param arity
	 *            the number of arguments being evaluated.
	 */
	public XPathFunction resolveFunction(QName qName, int arity) {
		if (null != functionMap) {
			Object result = null;
			Iterator<String> keysIter = functionMap.keySet().iterator();
			while (keysIter.hasNext()) {
				String localName = keysIter.next();
				result = functionMap.get(localName).resolveFunction(qName,
						arity);
				if (null != result) {
					return (XPathFunction) result;
				}
			}
		}
		return null;
	}

	/**
	 * Adds a function to the resolver collection. (Any previously added
	 * function of the same local name will be replaced).
	 * 
	 * @param function
	 *            the function to add.
	 */
	public void addFunction(AbstractXPathFunction function) {
		if (null == functionMap) {
			functionMap = new HashMap<String, AbstractXPathFunction>();
		}
		if (null != function) {
			functionMap.put(function.getLocalName(), function);
		}
	}
}
