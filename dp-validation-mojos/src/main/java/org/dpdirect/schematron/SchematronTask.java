package org.dpdirect.ti.schematron;
//package org.dpdirect.schematron;
//
//import java.io.ByteArrayInputStream;
//import java.io.ByteArrayOutputStream;
//import java.io.File;
//import java.io.FileInputStream;
//import java.io.FileOutputStream;
//import java.io.InputStream;
//import java.io.OutputStream;
//
//import javax.xml.transform.ErrorListener;
//import javax.xml.transform.Templates;
//import javax.xml.transform.Transformer;
//import javax.xml.transform.TransformerException;
//import javax.xml.transform.TransformerFactory;
//import javax.xml.transform.stream.StreamResult;
//import javax.xml.transform.stream.StreamSource;
//
//import net.sf.saxon.TransformerFactoryImpl;
//
//import org.apache.tools.ant.BuildException;
//import org.apache.tools.ant.Task;
//import org.xml.sax.Attributes;
//import org.xml.sax.InputSource;
//import org.xml.sax.SAXException;
//import org.xml.sax.XMLReader;
//import org.xml.sax.helpers.DefaultHandler;
//import org.xml.sax.helpers.XMLReaderFactory;
//
///**
// * An Ant Task implementation of a 'Schematron' assertion process using a single
// * input schema and single input xml file.
// * <p/>
// * Results are output to a file called 'result.xml' in the current directory.
// * <p/>
// * The task ignores the system JAXP setting for the TransformerFactory and
// * directly instantiates a <code>net.sf.saxon.TransformerFactoryImpl</code>
// * factory. Hence the task requires <code>saxon9.jar</code> (or later) to be
// * present on the taskdef classpath.
// * 
// * @author N.A.
// */
//public class SchematronTask extends Task {
//
//	/**
//	 * The ISO stylesheet to expand inclusions.
//	 */
//	public static final String EXPAND_INCLUSIONS_XSLT = "/iso_dsdl_include.xsl";
//
//	/**
//	 * The ISO stylesheet to expand abstract patterns.
//	 */
//	public static final String EXPAND_ABSTRACT_XSLT = "/iso_abstract_expand.xsl";
//
//	/**
//	 * The ISO stylesheet to compile the schematron stylesheet.
//	 */
//	public static final String SVRL_COMPILE_XSLT = "/iso_svrl_for_xslt2.xsl";
//
//	/**
//	 * The name of the resulting output file (written to the current directory
//	 * at runtime).
//	 */
//	public static final String RESULT_FILE = "result.xml";
//
//	/**
//	 * A TransfomerFactory for generating transform objects.
//	 */
//	private TransformerFactory factory = null;
//
//	/**
//	 * The input schematron schema.
//	 */
//	private File schema = null;
//
//	/**
//	 * The target or source file to apply the schematron assertions to.
//	 */
//	private File srcFile = null;
//
//	/**
//	 * The standard ant task 'failonerror' flag.
//	 */
//	private boolean failOnError = true;
//
//	/**
//	 * Constructs a new <code>SchematronTask</code> object.
//	 */
//	public SchematronTask() {
//		factory = new TransformerFactoryImpl();
//	}
//
//	/**
//	 * Executes the task.
//	 * 
//	 * @throws BuildException
//	 *             if there is a fatal error running the task.
//	 */
//	public void execute() throws BuildException {
//		// Validate the task input.
//		if (schema == null || schema.isDirectory()) {
//			throw new BuildException("No input schema has been specified.");
//		}
//		if (!schema.exists() || !schema.canRead() || !schema.isFile()) {
//			throw new BuildException("Input schema " + schema
//					+ " cannot be read.");
//		}
//		if (srcFile == null || srcFile.isDirectory()) {
//			throw new BuildException("No srcfile has been specified.");
//		}
//		if (!srcFile.exists() || !srcFile.canRead() || !srcFile.isFile()) {
//			throw new BuildException("The srcfile " + srcFile
//					+ " cannot be read.");
//		}
//		log("Applying schematron schema '" + schema + "' to file '" + srcFile
//				+ "'");
//		final String TEMP_COMPILED_FILE = schema.getName() + "-comp.xsl";
//		try {
//			ByteArrayOutputStream outputStream = new ByteArrayOutputStream();
//			// Expand inclusions
//			apply(SchematronTask.class.getResource(EXPAND_INCLUSIONS_XSLT)
//					.toString(), new FileInputStream(schema), outputStream);
//			outputStream.flush();
//			// Expand abstract patterns.
//			apply(SchematronTask.class.getResource(EXPAND_ABSTRACT_XSLT)
//					.toString(), new ByteArrayInputStream(outputStream
//					.toByteArray()),
//					(outputStream = new ByteArrayOutputStream()));
//			outputStream.flush();
//			// Compile
//			apply(SchematronTask.class.getResource(SVRL_COMPILE_XSLT)
//					.toString(), new ByteArrayInputStream(outputStream
//					.toByteArray()),
//					(outputStream = new ByteArrayOutputStream()));
//			outputStream.flush();
//			FileOutputStream compiled = new FileOutputStream(TEMP_COMPILED_FILE);
//			compiled.write(outputStream.toByteArray());
//			compiled.flush();
//			compiled.close();
//			// Validate
//			FileOutputStream resultFile = new FileOutputStream(RESULT_FILE);
//			apply(TEMP_COMPILED_FILE, new FileInputStream(srcFile), resultFile);
//			resultFile.flush();
//			resultFile.close();
//			parseResultsDocument();
//		} catch (Exception e) {
//			if (failOnError) {
//				throw new BuildException(e);
//			} else {
//				log("[error] " + e.getMessage());
//			}
//		} finally {
//			try {
//				// Clean up temporary output.
//				File temp = new File(TEMP_COMPILED_FILE);
//				temp.delete();
//			} catch (Exception e2) {
//				// Ignore
//			}
//		}
//	}
//
//	/**
//	 * Parses the results file and logs messages if there are failed assertions
//	 * or reports in the results document.
//	 * 
//	 * @throws BuildException
//	 *             if there is an error attempting to parse the results document
//	 *             (or if there are failed assertions).
//	 */
//	private void parseResultsDocument() throws BuildException {
//		SchematronResultsHandler handler = new SchematronResultsHandler();
//		try {
//			XMLReader reader = XMLReaderFactory.createXMLReader();
//			reader.setContentHandler(handler);
//			reader.setErrorHandler(handler);
//			reader.parse(new InputSource(RESULT_FILE));
//		} catch (Exception e) {
//			throw new BuildException(e);
//		}
//		if (handler.hasFailedAssertions()) {
//			throw new BuildException(
//					"There are schematron assertion failures. See '"
//							+ RESULT_FILE + "' file for full details.");
//		}
//	}
//
//	/**
//	 * Sets the schema.
//	 * 
//	 * @param schema
//	 *            the schema to set.
//	 */
//	public void setSchema(File schema) {
//		this.schema = schema;
//	}
//
//	/**
//	 * Sets the source/input file.
//	 * 
//	 * @param schema
//	 *            the source/input file. to set.
//	 */
//	public void setSrcFile(File srcFile) {
//		this.srcFile = srcFile;
//	}
//
//	/**
//	 * Sets a boolean flag to control the output of BuildExceptions.
//	 * 
//	 * @param failOnError
//	 *            true if the execute method show throw exceptions on error;
//	 *            false otherwise.
//	 */
//	public void setFailOnError(boolean failOnError) {
//		this.failOnError = failOnError;
//	}
//
//	/**
//	 * Applies a stylesheet to a source document and writes the transformation
//	 * output to an output stream.
//	 * 
//	 * @param xslUrl
//	 *            the URL or path of the XSL stylesheet.
//	 * 
//	 * @param sourceInputStream
//	 *            an input stream of the source document content.
//	 * 
//	 * @param outputStream
//	 *            an output stream to write the transformation output to.
//	 * 
//	 * @throws RuntimeException
//	 *             if there is an error executing the transformation.
//	 */
//	public void apply(String xslUrl, InputStream sourceInputStream,
//			OutputStream outputStream) throws RuntimeException {
//		try {
//			StreamSource xslSource = new StreamSource(xslUrl);
//			xslSource.setSystemId(xslUrl);
//			Templates template = factory.newTemplates(xslSource);
//			Transformer transformer = template.newTransformer();
//			transformer.setErrorListener(new CustomErrorListener());
//			transformer.transform(new StreamSource(sourceInputStream),
//					new StreamResult(outputStream));
//		} catch (Exception e) {
//			throw new RuntimeException(e);
//		}
//	}
//
//	/**
//	 * A custom error listener to re-throw exceptions as RuntimeExceptions.
//	 */
//	public class CustomErrorListener implements ErrorListener {
//		public void error(TransformerException ex) throws TransformerException {
//			throw new RuntimeException(ex);
//		}
//
//		public void fatalError(TransformerException ex)
//				throws TransformerException {
//			throw new RuntimeException(ex);
//		}
//
//		public void warning(TransformerException ex)
//				throws TransformerException {
//			log("[transform-warning] " + ex.getMessage());
//		}
//	}
//
//	/**
//	 * A SAX2 ContentHandler to parse SVRL results documents and perform event
//	 * handling of assertion failures.
//	 */
//	public class SchematronResultsHandler extends DefaultHandler {
//
//		private static final String SVRL_NS = "http://purl.oclc.org/dsdl/svrl";
//		private static final String FAILED_ASSERT_LOCALNAME = "failed-assert";
//		private static final String SUCCESS_REPORT_LOCALNAME = "successful-report";
//		private static final String TEST_LOCALNAME = "test";
//		private static final String lOCATION_LOCALNAME = "location";
//		private static final String TEXT_LOCALNAME = "text";
//
//		/**
//		 * Local cache of the character data parsed from text nodes.
//		 */
//		private StringBuilder characters = new StringBuilder("");
//
//		private boolean hasFailedAssertions = false;
//
//		private boolean hasSuccessfulReports = false;
//
//		private boolean inFailedAssertion = false;
//
//		private boolean inSuccessfulReport = false;
//
//		private String failedAssertionTest = null;
//
//		private String successfulReportTest = null;
//
//		private String failedAssertionLocation = null;
//
//		private String successfulReportLocation = null;
//
//		private String failedAssertionText = null;
//
//		private String successfulReportText = null;
//
//		public SchematronResultsHandler() {
//			super();
//		}
//
//		public boolean hasFailedAssertions() {
//			return hasFailedAssertions;
//		}
//
//		public boolean hasSuccessfulReports() {
//			return hasSuccessfulReports;
//		}
//
//		@Override
//		public void characters(char[] ch, int start, int length)
//				throws SAXException {
//			characters.append(ch, start, length);
//		}
//
//		@Override
//		public void startElement(String uri, String name, String qName,
//				Attributes atts) {
//			characters = new StringBuilder("");
//			if (FAILED_ASSERT_LOCALNAME.equals(name) && SVRL_NS.equals(uri)) {
//				failedAssertionTest = atts.getValue(TEST_LOCALNAME);
//				failedAssertionLocation = atts.getValue(lOCATION_LOCALNAME);
//				hasFailedAssertions = true;
//				inFailedAssertion = true;
//			} else if (SUCCESS_REPORT_LOCALNAME.equals(name)
//					&& SVRL_NS.equals(uri)) {
//				successfulReportTest = atts.getValue(TEST_LOCALNAME);
//				successfulReportLocation = atts.getValue(lOCATION_LOCALNAME);
//				hasSuccessfulReports = true;
//				inSuccessfulReport = true;
//			}
//		}
//
//		@Override
//		public void endElement(String uri, String name, String qName) {
//			if (FAILED_ASSERT_LOCALNAME.equals(name) && SVRL_NS.equals(uri)) {
//				log("[failed-assertion] test=\"" + failedAssertionTest
//						+ "\" location=\"" + failedAssertionLocation
//						+ "\" text=\"" + failedAssertionText + "\"");
//				inFailedAssertion = false;
//				failedAssertionTest = null;
//				failedAssertionLocation = null;
//				failedAssertionText = null;
//			} else if (TEXT_LOCALNAME.equals(name) && SVRL_NS.equals(uri)
//					&& inFailedAssertion) {
//				failedAssertionText = characters.toString();
//			} else if (SUCCESS_REPORT_LOCALNAME.equals(name)
//					&& SVRL_NS.equals(uri)) {
//				log("[successful-report] test=\"" + successfulReportTest
//						+ "\" location=\"" + successfulReportLocation
//						+ "\" text=\"" + successfulReportText + "\"");
//				inSuccessfulReport = false;
//				successfulReportTest = null;
//				successfulReportLocation = null;
//				successfulReportText = null;
//			} else if (TEXT_LOCALNAME.equals(name) && SVRL_NS.equals(uri)
//					&& inSuccessfulReport) {
//				successfulReportText = characters.toString();
//			}
//		}
//
//		@Override
//		public void endDocument() {
//			String reportPostfix = (hasSuccessfulReports) ? " There was one or more successful reports."
//					: "";
//			if (hasFailedAssertions) {
//				log("Done. One or more assertions failed." + reportPostfix);
//			} else {
//				log("Done. All assertions passed." + reportPostfix);
//			}
//		}
//
//	}
//
//}
