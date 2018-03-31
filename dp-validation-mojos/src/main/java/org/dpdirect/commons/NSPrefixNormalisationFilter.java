package org.dpdirect.commons;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.util.Hashtable;
import java.util.Iterator;

import javax.xml.parsers.SAXParserFactory;
import javax.xml.transform.OutputKeys;
import javax.xml.transform.Transformer;
import javax.xml.transform.TransformerFactory;
import javax.xml.transform.sax.SAXTransformerFactory;
import javax.xml.transform.sax.TransformerHandler;
import javax.xml.transform.stream.StreamResult;

import org.xml.sax.Attributes;
import org.xml.sax.InputSource;
import org.xml.sax.SAXException;
import org.xml.sax.XMLFilter;
import org.xml.sax.XMLReader;
import org.xml.sax.helpers.AttributesImpl;
import org.xml.sax.helpers.XMLFilterImpl;

/**
 * A SAX2 filter to do simple XML Namespace prefix normalisation. For use in
 * combination with XML Canonicalisation (which, by definition, is not allowed
 * to rewrite or normalise NS prefixes in any way).
 * 
 * Note: currently suitable for single-threaded use only.
 * 
 * @author N.A.
 * 
 */
public class NSPrefixNormalisationFilter extends XMLFilterImpl {

	/**
	 * A hash table of namespace URIs, passed to the startPrefixMapping()
	 * method. It hashes the URIs to simple sequential 'ns1', 'ns2' style
	 * prefixes.
	 */
	private Hashtable<String, String> uriToPrefixMap = new Hashtable<String, String>();

	/**
	 * A hash table of the new/old prefixes (where new is used as the key
	 * because old prefixes could potentially by reused for different URIs in
	 * different parts of the input document.
	 */
	private Hashtable<String, String> newToOldPrefixMap = new Hashtable<String, String>();

	/**
	 * Applies the filter as part of a SAX pipeline, returning a version of the
	 * input xml document with normalised namespace prefixes.
	 * 
	 * @param inputStream
	 *            an input stream of a well formed XML 1.0 document.
	 * 
	 * @return a version of the input xml document with normalised namespace
	 *         prefixes.
	 * 
	 * @throws IOException
	 *             if there is an IO error.
	 */
	public byte[] apply(InputStream inputStream) throws IOException {
		// Initialise the state
		uriToPrefixMap = new Hashtable<String, String>();
		newToOldPrefixMap = new Hashtable<String, String>();
		// byte[] inputBytes =
		// XslTestSuiteUtils.readInputStreamBytes(inputStream);
		ByteArrayOutputStream outputStream = new ByteArrayOutputStream();
		TransformerFactory factory = TransformerFactory.newInstance();
		try {
			if (!factory.getFeature(SAXTransformerFactory.FEATURE_XMLFILTER)) {
				System.err.println("SAX Filters are not supported");
			} else {
				SAXTransformerFactory saxFactory = (SAXTransformerFactory) factory;
				XMLFilter preFilter = new NSPrefixNormalisationFilter();
				XMLReader parser = SAXParserFactory.newInstance()
						.newSAXParser().getXMLReader();
				parser.setFeature("http://xml.org/sax/features/namespaces",
						true);
				parser.setFeature(
						"http://xml.org/sax/features/namespace-prefixes", true);
				preFilter.setParent(parser);

				TransformerHandler serializer = saxFactory
						.newTransformerHandler();
				serializer.setResult(new StreamResult(outputStream));
				Transformer trans = serializer.getTransformer();
				trans.setOutputProperty(OutputKeys.METHOD, "xml");
				trans.setOutputProperty(OutputKeys.INDENT, "yes");
				preFilter.setContentHandler(serializer);
				preFilter.parse(new InputSource(inputStream));
			}
		} catch (Exception e) {
			throw new RuntimeException(e);
		}
		outputStream.flush();
		return outputStream.toByteArray();
	}

	public void startElement(String uri, String localName, String qName,
			Attributes atts) throws SAXException {
		String newUri = (null != uri && uriToPrefixMap.containsKey(uri)) ? ((String) uriToPrefixMap
				.get(uri))
				: uri;

		// NOTE: Java 6 (and probably 5) requires the following (but it results
		// in duplicate xmlns decs in Java 1.4):
		// if (uriToPrefixMap.containsKey(uri)) {
		// super.startPrefixMapping(((String) uriToPrefixMap.get(uri)), uri);
		// }

		// Check the attributes
		AttributesImpl newAtts = null;
		if (null != atts) {
			newAtts = new AttributesImpl();
			for (int i = 0; i < atts.getLength(); i++) {
				String attUri = atts.getURI(i);
				String attQName = atts.getQName(i);
				if (null != attUri && uriToPrefixMap.containsKey(attUri)) {
					attQName = uriToPrefixMap.get(attUri) + ":"
							+ atts.getLocalName(i);
				}
				if (!attQName.startsWith("xmlns:")) {
					newAtts.addAttribute(atts.getURI(i), atts.getLocalName(i),
							attQName, atts.getType(i), atts.getValue(i));
				}
			}
		}
		if (uriToPrefixMap.containsKey(uri)) {
			super.startElement(uri, localName, newUri + ":" + localName,
					newAtts);
			// NOTE: Java 6 (and probably 5) requires the following (but it
			// results in duplicate xmlns decs in Java 1.4):
			// super.endPrefixMapping(((String) uriToPrefixMap.get(uri)));

		} else {
			super.startElement(uri, localName, qName, newAtts);
		}
	}

	public void endElement(String uri, String localName, String qName)
			throws SAXException {
		if (uriToPrefixMap.containsKey(uri)) {
			super.endElement(uri, localName, ((String) uriToPrefixMap.get(uri))
					+ ":" + localName);
		} else {
			super.endElement(uri, localName, qName);
		}
	}

	public void startPrefixMapping(String prefix, String uri)
			throws SAXException {
		if (uriToPrefixMap.containsKey(uri)) {
			super.startPrefixMapping(((String) uriToPrefixMap.get(uri)), uri);
		} else {
			String newPrefix = "ns" + (uriToPrefixMap.size() + 1);
			newToOldPrefixMap.put(newPrefix, prefix);
			uriToPrefixMap.put(uri, newPrefix);
			super.startPrefixMapping(newPrefix, uri);
		}
	}

	public void endPrefixMapping(String prefix) throws SAXException {
		String newPrefix = prefix;
		for (Iterator<String> iter = newToOldPrefixMap.keySet().iterator(); iter
				.hasNext();) {
			String key = iter.next();
			if (((String) newToOldPrefixMap.get(key)).equals(prefix)) {
				newPrefix = key;
				break;
			}
		}
		super.endPrefixMapping(newPrefix);
	}
}
