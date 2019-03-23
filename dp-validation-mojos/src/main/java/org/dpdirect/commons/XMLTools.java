package org.dpdirect.commons;

import java.io.ByteArrayInputStream;
import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.MalformedURLException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.parsers.ParserConfigurationException;
import javax.xml.transform.sax.SAXSource;
import javax.xml.xpath.XPath;
import javax.xml.xpath.XPathConstants;
import javax.xml.xpath.XPathExpressionException;
import javax.xml.xpath.XPathFactory;

import net.sf.saxon.dom.AttrOverNodeInfo;
import net.sf.saxon.om.NodeInfo;
import net.sf.saxon.trans.XPathException;
import net.sf.saxon.xpath.XPathEvaluator;

import org.apache.xml.security.Init;
import org.apache.xml.security.c14n.Canonicalizer;
import org.w3c.dom.Document;
import org.w3c.dom.Node;
import org.xml.sax.InputSource;
import org.xml.sax.SAXException;

import org.dpdirect.commons.xpath.DpXPathFunctionResolver;
import org.dpdirect.commons.xpath.NamespaceContextMap;

/**
 * A collection of XML utility methods.
 * 
 * @author N.A.
 * 
 */
public class XMLTools {

	/**
	 * A local cached JAXP XPathFactory instance.
	 */
	private static XPathFactory xpathFactory = null;

	/**
	 * Gets the static class instance of the XPathFactory.
	 * 
	 * @return the static class instance of the XPathFactory.
	 */
	private static XPathFactory getXPathFactory() {
		if (null == xpathFactory) {
			// Use the Saxon factory, regardless of JAXP system property
			// settings.
			xpathFactory = new net.sf.saxon.xpath.XPathFactoryImpl();
		}
		return xpathFactory;
	}

	/**
	 * Tests a byte array for a big-endian or little-endian byte order mark
	 * (BOM).
	 * 
	 * @param bytes
	 *            the byte array to test.
	 * @return true if the byte array begin with the UTF-16 big-endian or
	 *         little-endian byte order mark (BOM); false otherwise.
	 */
	public static boolean isUTF16(byte[] bytes) {
		if (null != bytes && bytes.length > 1) {
			if ((bytes[0] == (byte) 0xFE) && (bytes[1] == (byte) 0xFF)) {
				return true;
			} else if ((bytes[0] == (byte) 0xFF) && (bytes[1] == (byte) 0xFE)) {
				return true;
			}
		}
		return false;
	}

	/**
	 * Tests if two well formed xml documents are canonically equivalent. In
	 * additional to (XML) canonicalization it also performs XML namespace
	 * prefix normalisation and whitespace normalisation before returning the
	 * result of a simple byte-equivalence test.
	 * 
	 * @param doc1Bytes
	 *            a byte array representation of a well formed xml document.
	 * 
	 * @param doc2Bytes
	 *            a byte array representation of a well formed xml document.
	 * 
	 * @param verbose
	 *            flag to indicate whether to write to System.out in the event
	 *            of non-equivalent results.
	 * 
	 * @return true if the documents are equivalent; false otherwise.
	 */
	public static boolean canonicallyEquivalent(byte[] doc1Bytes,
			byte[] doc2Bytes, boolean verbose) {
		// Test for Canonical equivalence.
		try {
			Init.init();
			Canonicalizer c = Canonicalizer
					.getInstance(Canonicalizer.ALGO_ID_C14N_EXCL_OMIT_COMMENTS);
			NSPrefixNormalisationFilter filter = new NSPrefixNormalisationFilter();

			byte[] canonBytes1 = c.canonicalize(doc1Bytes);
			byte[] canonBytes2 = c.canonicalize(doc2Bytes);

			byte[] prefixNormBytes1 = filter.apply(new ByteArrayInputStream(
					canonBytes1));
			byte[] prefixNormBytes2 = filter.apply(new ByteArrayInputStream(
					canonBytes2));

			// Strip all whitespace and compare the non-whitespace character
			// content.
			String doc1 = new String(prefixNormBytes1).replaceAll("\\s", "");
			String doc2 = new String(prefixNormBytes2).replaceAll("\\s", "");
			boolean areEqual = doc1.equals(doc2);
			if (!areEqual && verbose) {
				System.out
						.println("====================== Canonical Doc [1] =====================");
				System.out.println(new String(prefixNormBytes1));
				System.out
						.println("==============================================================");
				System.out
						.println("====================== Canonical Doc [2] =====================");
				System.out.println(new String(prefixNormBytes2));
				System.out
						.println("==============================================================");
			}
			return areEqual;
		} catch (Exception e) {
			throw new RuntimeException(e);
		}
	}

	/**
	 * Determines if an XPath expression is syntactically valid.
	 * 
	 * @param xpath
	 *            the expression to test.
	 * 
	 * @param namespaceBindings
	 *            an optional map of xmlns/prefix bindings (can be null).
	 * 
	 * @param outstream
	 *            an optional outputstream object to write details of invalid
	 *            expression exceptions, if they occur (can be null in which
	 *            case the method will just return false).
	 * 
	 * @return true if the XPath expression is syntactically valid; false
	 *         otherwise.
	 */
	public static boolean isValidXPathExpression(String xpath,
			HashMap<String, String> namespaceBindings, OutputStream outstream) {
		XPath xpathObj = getXPathFactory().newXPath();
		try {
			xpathObj.setNamespaceContext(new NamespaceContextMap(
					namespaceBindings, true));
			xpathObj.setXPathFunctionResolver(DpXPathFunctionResolver
					.getInstance());
			xpathObj.compile(xpath);
		} catch (XPathExpressionException e) {
			String cause = e.getCause().toString();
			if (null == cause) {
				return false;
			}
			if (cause.startsWith("net.sf.saxon.trans.XPathException:")) {
				cause = cause.substring(cause.indexOf(":") + 1).trim();
			}
			if (null != outstream) {
				try {
					outstream.write(cause.getBytes("UTF-8"));
					outstream.flush();
				} catch (IOException e2) {
					// Ignore.
				}
			}
			return false;
		}
		return true;
	}

	/**
	 * 
	 * Evaluates an XPath expression on a document Node object.
	 * 
	 * @param xpath
	 *            the XPath expression to evaluate.
	 * 
	 * @param node
	 *            the source node.
	 * 
	 * @return <code>String</code> representations of the XPath evaluation
	 *         result.
	 * 
	 * @throws XPathExpressionException
	 *             if there is an XPath error.
	 */
	public static String evaluateXPath(String xpath, Node node)
			throws XPathExpressionException {
		return evaluateXPath(xpath, node, null);
	}

	/**
	 * 
	 * Evaluates an XPath expression on a document Node object.
	 * 
	 * @param xpath
	 *            the XPath expression to evaluate.
	 * 
	 * @param node
	 *            the source node.
	 * 
	 * @param namespaceBindings
	 *            an optional map of xmlns/prefix bindings (can be null).
	 * 
	 * @return <code>String</code> representations of the XPath evaluation
	 *         result.
	 * 
	 * @throws XPathExpressionException
	 *             if there is an XPath error.
	 */
	public static String evaluateXPath(String xpath, Node node,
			HashMap<String, String> namespaceBindings)
			throws XPathExpressionException {
		XPath xpathObj = getXPathFactory().newXPath();
		xpathObj.setNamespaceContext(new NamespaceContextMap(namespaceBindings,
				true));
		xpathObj.setXPathFunctionResolver(DpXPathFunctionResolver
				.getInstance());
		javax.xml.xpath.XPathExpression xpathExp = xpathObj.compile(xpath);
		return (String) xpathExp.evaluate(node, XPathConstants.STRING);
	}

	/**
	 * Evaluates an XPath expression on document located by a given path. Then
	 * performs the string conversion on each result. (Note: for Node results
	 * this representation may not be very useful).
	 * 
	 * @param xpath
	 *            the XPath expression to evaluate.
	 * 
	 * @param documentPath
	 *            the source document path.
	 * 
	 * @param namespaceBindings
	 *            an optional map of xmlns/prefix bindings (can be null).
	 * 
	 * @throws XPathException
	 *             if there is an error evaluating the XPath.
	 * 
	 * @return a List of <code>String</code> representations of the XPath
	 *         evaluation result list.
	 * 
	 * @throws XPathException
	 *             if there is an error evaluating the expression.
	 * 
	 * @throws XPathExpressionException
	 *             if there is an error compiling the expression.
	 */
	@SuppressWarnings("unchecked")
	public static List<String> evaluateXPathToStrings(String xpath,
			String documentPath, HashMap<String, String> namespaceBindings)
			throws XPathException, XPathExpressionException {
		List<String> stringList = new ArrayList<String>();
		List resultList = evaluateXPath(xpath, documentPath, namespaceBindings);
		if (null != resultList) {
			Iterator iter = resultList.iterator();
			while (iter.hasNext()) {
				Object o = iter.next();
				String value = null;
				if (o instanceof NodeInfo) {
					NodeInfo node = (NodeInfo) o;
					value = node.getStringValue();
				} else if (o instanceof AttrOverNodeInfo) {
					AttrOverNodeInfo nodeInfo = (AttrOverNodeInfo) o;
					value = nodeInfo.getNodeValue();
				} else {
					value = String.valueOf(o);
				}
				stringList.add(value);
			}
		}
		return stringList;
	}

	/**
	 * Evaluates an XPath expression on document located by a given path.
	 * 
	 * @param xpath
	 *            the XPath expression to evaluate.
	 * 
	 * @param documentPath
	 *            the source document path.
	 * 
	 * @param namespaceBindings
	 *            an optional map of xmlns/prefix bindings (can be null).
	 * 
	 * @throws XPathException
	 *             if there is an error evaluating the XPath.
	 * 
	 * @return a List of <code>NodeInfo</code> results.
	 * 
	 * @throws XPathException
	 *             if there is an error evaluating the expression.
	 * 
	 * @throws XPathExpressionException
	 *             if there is an error compiling the expression.
	 */
	@SuppressWarnings("unchecked")
	public static List evaluateXPath(String xpath, String documentPath,
			HashMap<String, String> namespaceBindings) throws XPathException,
			XPathExpressionException {
		XPath xpathObj = getXPathFactory().newXPath();
		InputSource inputSource;
		try {
			inputSource = new InputSource(new File(documentPath).toURI()
					.toURL().toString());
		} catch (MalformedURLException e) {
			throw new RuntimeException(e);
		}
		SAXSource saxSource = new SAXSource(inputSource);
		NodeInfo doc = ((XPathEvaluator) xpathObj).setSource(saxSource);
		xpathObj.setNamespaceContext(new NamespaceContextMap(namespaceBindings,
				true));
		xpathObj.setXPathFunctionResolver(DpXPathFunctionResolver
				.getInstance());
		javax.xml.xpath.XPathExpression xpathExp = xpathObj.compile(xpath);
		Object results = xpathExp.evaluate(doc, XPathConstants.NODESET);
		try {
			return (List) results;
		} catch (ClassCastException ex) {
			if (results instanceof net.sf.saxon.dom.DOMNodeList) {
				// Requires an explicit cast.
				List list = new ArrayList();
				net.sf.saxon.dom.DOMNodeList nodeList = (net.sf.saxon.dom.DOMNodeList) results;
				for (int i = 0; i < nodeList.getLength(); i++) {
					list.add(nodeList.item(i));
				}
				return list;
			} else {
				// Throw the cast exception.
				throw ex;
			}
		}

	}

	/**
	 * Gets a DOM document from an InputStream. Using the default
	 * "javax.xml.parsers.DocumentBuilderFactory".
	 * 
	 * @param inputStream
	 *            the XML document input stream.
	 * 
	 * @return a DOM document object.
	 * 
	 * @throws IOException
	 *             if there is an IO error.
	 * 
	 * @throws SAXException
	 *             if there is a SAX parsing error.
	 * 
	 * @throws ParserConfigurationException
	 *             if there is a parser config error.
	 */
	public static Document parseDocument(InputStream inputStream)
			throws IOException, SAXException, ParserConfigurationException {
		DocumentBuilderFactory docFactory = DocumentBuilderFactory
				.newInstance();
		docFactory.setNamespaceAware(true);
		return docFactory.newDocumentBuilder().parse(inputStream);
	}

	/**
	 * Replaces the prefixes bound to namespace URI's within a single XML
	 * document from a HashMap of replacement prefix bindings (typically sourced
	 * from a target XML Schema).
	 * <p>
	 * Warning: This method is only intended as a test-time utility. It replaces
	 * sample document prefixes with those declared in the target documents
	 * schema. It is based on regular expression pattern matching, hence it is
	 * not XML aware (e.g does not handle entities etc) and can only be used on
	 * files with UTF-8 or UTF-16 encoding. <b>This approach is NOT suitable for
	 * any type of production XML processing.</b>
	 * </p>
	 * 
	 * @param inputStream
	 *            an input stream containing a well-formed UTF-8 or UTF-16
	 *            encoded xml document.
	 * @param outputStream
	 *            an output stream to write the resulting xml document to.
	 *            (Output is encoded as UTF-8, regardless of the input
	 *            encoding).
	 * @param prefixMap
	 *            a HashMap of namespace prefixes (keys) and namespace URIs
	 *            (values).
	 * @throws IOException
	 *             if there is an error reading or writing to the IO streams.
	 */
	public static void replacePrefixNames(InputStream inputStream,
			OutputStream outputStream, HashMap<String, String> prefixMap)
			throws IOException {
		byte[] docBytes = IOTools.readInputStreamBytes(inputStream);
		String docString = new String(docBytes, (isUTF16(docBytes)) ? "UTF-16"
				: "UTF-8");
		if (null != prefixMap) {
			for (Iterator<String> prefixIter = prefixMap.keySet().iterator(); prefixIter
					.hasNext();) {
				String prefix = prefixIter.next();
				String nsURI = prefixMap.get(prefix);
				final String XMLNS_DEC_REGEX = "\\s+xmlns:([^=]+)=[\"']+"
						+ nsURI + "[\"']+";
				final String XMLNS_DEC_REPLACEMENT = " xmlns:" + prefix + "=\""
						+ nsURI + "\"";
				Pattern pattern = Pattern.compile(XMLNS_DEC_REGEX);
				Matcher matcher = pattern.matcher(docString);
				String currentPrefixName = "";
				if (matcher.find()) {
					currentPrefixName = matcher.group(1);
					docString = docString.replaceAll(XMLNS_DEC_REGEX,
							XMLNS_DEC_REPLACEMENT);
					docString = docString.replaceAll("([</\\s])"
							+ currentPrefixName + ":", "$1" + prefix + ":");
				}
			}
		}
		outputStream.write(docString.getBytes("UTF-8"));
	}

}
