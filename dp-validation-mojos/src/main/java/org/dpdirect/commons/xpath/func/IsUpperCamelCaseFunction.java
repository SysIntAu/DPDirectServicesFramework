package org.dpdirect.commons.xpath.func;

import java.util.List;

import javax.xml.namespace.QName;
import javax.xml.xpath.XPathFunctionException;

import org.dpdirect.commons.xpath.AbstractXPathFunction;

/**
 * A custom XPathFunction to test for "UpperCamelCase" naming convention.
 * 
 * @author N.A.
 */
public class IsUpperCamelCaseFunction extends AbstractXPathFunction {

	/**
	 * A local name for the function.
	 */
	public static final String FUNCTION_LOCAL_NAME = "is-upper-camel-case";

	/**
	 * A QName for the function.
	 */
	public static final QName FUNCTION_QNAME = new QName(
			XPATH_FUNCTIONS_NS_URI, FUNCTION_LOCAL_NAME);

	/**
	 * Singleton class instance.
	 */
	private static AbstractXPathFunction instance = null;

	/**
	 * Private constructor for instantiating singleton instance.
	 */
	private IsUpperCamelCaseFunction() {
	}

	/**
	 * Gets the class instance.
	 * 
	 * @return the shared class instance.
	 */
	public static AbstractXPathFunction getInstance() {
		if (null == instance) {
			instance = new IsUpperCamelCaseFunction();
		}
		return instance;
	}

	/**
	 * Gets the local name of the function.
	 * 
	 * @return the local name of the function.
	 */
	public String getLocalName() {
		return FUNCTION_LOCAL_NAME;
	}

	/**
	 * Gets the QName of the function.
	 * 
	 * @return the QName of the function.
	 */
	public QName getQName() {
		return FUNCTION_QNAME;
	}

	/**
	 * Gets a list of the number of arguments the function requires. A list is
	 * required to cater for overloaded function signatures.
	 * 
	 * @return a list of the number of arguments the function requires.
	 */
	public int[] getArityList() {
		return new int[] { 1 };
	}

	/**
	 * Implementation of the DPDIRECTXPathFunction interface method to evaluate the
	 * function on a list of input arguments.
	 * 
	 * @return the function result.
	 */
	@SuppressWarnings("unchecked")
	public Object evaluate(List arguments) throws XPathFunctionException {
		Object arg;
		final String ERROR_MSG = getInformalName()
				+ " expects an xs:string argument";
		try {
			arg = arguments.get(0);
		} catch (Exception e) {
			throw new XPathFunctionException(ERROR_MSG);
		}
		if (!(arg instanceof String)) {
			throw new XPathFunctionException(ERROR_MSG
					+ ". But received argument of type "
					+ arg.getClass().getName());
		}
		// Test the string for UpperCamelCase compliance.
		if (((String) arg).matches("[A-Z]+[a-zA-Z0-9]*")) {
			return new Boolean(true);
		}
		return new Boolean(false);
	}
}
