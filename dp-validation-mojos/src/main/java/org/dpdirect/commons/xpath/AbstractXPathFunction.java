package org.dpdirect.commons.xpath;

import javax.xml.namespace.QName;
import javax.xml.xpath.XPathFunction;
import javax.xml.xpath.XPathFunctionResolver;

/**
 * Abstract representation of a custom DPDIRECT XPath function.
 * 
 * <p>
 * All functions are in the namespace:
 * <code>http://www.dpdirect.org/Namespace/OxygenPlugins/XPathFunctions/V1.0</code>
 * </p>
 * 
 * @author N.A.
 */
public abstract class AbstractXPathFunction implements XPathFunction,
		XPathFunctionResolver {

	/**
	 * A namespace URI for the custom DPDIRECT XPath functions.
	 */
	public static final String XPATH_FUNCTIONS_NS_URI = "http://www.dpdirect.org/Namespace/OxygenPlugins/XPathFunctions/V1.0";

	/**
	 * A standard namespace prefix for the custom DPDIRECT XPath functions.
	 */
	public static final String XPATH_FUNCTIONS_NS_PREFIX = "df";

	/**
	 * Gets the local name of the function.
	 * 
	 * @return the local name of the function.
	 */
	public abstract String getLocalName();

	/**
	 * Gets the QName of the function.
	 * 
	 * @return the QName of the function.
	 */
	public abstract QName getQName();

	/**
	 * Gets a list of the number of arguments the function requires. A list is
	 * required to cater for overloaded function signatures.
	 * 
	 * @return a list of the number of arguments the function requires.
	 */
	public abstract int[] getArityList();

	/**
	 * Implementation of the XPathFunctionResolver interface method to resolve a
	 * function based on its QName and number of arguments.
	 * 
	 * @param qName
	 *            the QName of the function.
	 * @param arity
	 *            the number of arguments being evaluated.
	 */
	public XPathFunction resolveFunction(QName qName, int arity) {
		if (qName.equals(getQName())) {
			int[] arityList = getArityList();
			for (int i = 0; i < arityList.length; i++) {
				if (arity == arityList[i]) {
					return this;
				}
			}
			return null;
		} else {
			return null;
		}
	}

	/**
	 * Gets an informal representation of the function name. E.g.
	 * "df:is-upper-camel-case()".
	 * 
	 * @return an informal representation of the function name.
	 */
	protected String getInformalName() {
		return XPATH_FUNCTIONS_NS_PREFIX + ":" + getLocalName() + "()";
	}

}
