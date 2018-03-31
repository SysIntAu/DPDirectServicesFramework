package org.dpdirect.batchvalidator;

import java.io.File;
import java.io.FileInputStream;
import java.util.HashMap;
import java.util.List;

import javax.xml.transform.ErrorListener;
import javax.xml.transform.TransformerException;
import javax.xml.transform.TransformerFactory;
import javax.xml.transform.stream.StreamSource;

import org.dpdirect.commons.XMLTools;
import org.dpdirect.commons.FilePatternFilter;
import org.apache.tools.ant.BuildException;
import org.apache.tools.ant.Task;

/**
 * A file validator for XSLT 1.0 and 2.0 schema files.
 * 
 * @author N.A.
 */
public class XSLTValidator extends Task implements FileValidator {

	/**
	 * A flag to indicate the occurrence of errors.
	 */
	private boolean hasErrors = false;
	
	/**
	 * The File to validate.
	 */
	private File file = null;

	/**
	 * A flag to indicate whether to allow XSLT 2.0 files.
	 */
	private boolean allowXslt2 = true;

	/**
	 * An error handler.
	 */
	private ValidationErrorHandler errorHandler = null;
	
	/**
	 * An XPath expression to select resource paths of imported or included
	 * resources within xsd, xslt or wsdl files.
	 */
	public static final String GET_RESOURCE_PATHS_XPATH = "//(xsl:import/@href|xsl:include/@href|xs:import/@schemaLocation|xs:include/@schemaLocation)";

	/**
	 * An map of xmlns/prefix bindings for xpath queries.
	 */
	private HashMap<String, String> namespaceBindingMap = new HashMap<String, String>();

	/**
	 * Constructs a new <code>XSLTValidator</code> object.
	 */
	public XSLTValidator() {
	}
	
	/* (non-Javadoc)
	 * task execute
	 */
	@Override
	public void execute() throws BuildException {
		performNamespaceBinding();
		try {
			this.setValidationErrorHandler(new ValidationErrorHandler() {
				@Override
				public void handleValidationError(String msg) {
					log("Validation Error: " + msg);
				}
			});
			validate();
			validateDependencies();
			System.out.println(this.file.getName()+ " successfully validated.");
		} catch (Exception e) {
			throw new BuildException(e.getMessage());
		}
	}
	
	/*
	 * (non-Javadoc)
	 *
	 *  performNamespaceBinding()
	 */
	public void performNamespaceBinding() {
		this.namespaceBindingMap.put("xs", "http://www.w3.org/2001/XMLSchema");
		this.namespaceBindingMap.put("xsd", "http://www.w3.org/2001/XMLSchema");
		this.namespaceBindingMap.put("xsi",
				"http://www.w3.org/2001/XMLSchema-instance");
		this.namespaceBindingMap.put("xsl",
				"http://www.w3.org/1999/XSL/Transform");
	}
	
	/*
	 * (non-Javadoc)
	 *
	 *  validateDependencies()
	 */
	public void validateDependencies() throws Exception {
		List<String> results = XMLTools
				.evaluateXPathToStrings(
						GET_RESOURCE_PATHS_XPATH, file
								.getAbsolutePath(),
						namespaceBindingMap);
		for (String result : results) {
			String dependencyPath = FilePatternFilter
					.normaliseDirPath(file.getParentFile()
							.getAbsolutePath(), false)
					+ result.trim();
			dependencyPath = FilePatternFilter
					.normaliseFilePath(dependencyPath, false);
			File dependentFile = new File(dependencyPath);
			if (!dependentFile.exists()) {
				throw new BuildException("Failed to read imported file at path '"
								+ dependencyPath
								+ "' referenced from file '"
								+ file.getAbsolutePath() + "'");
			}
		}
	}

	/**
	 * Determines whether XSLT 2.0 files will be allowed and validated using
	 * Saxon.
	 * 
	 * @param enabled
	 *            true to the enable the feature; false otherwise.
	 */
	public void setAllowXslt2(boolean enabled) {
		allowXslt2 = enabled;
	}

	/*
	 * (non-Javadoc)
	 * 
	 * @see au.gov.diac.oxygen.plugins.batchvalidator.FileValidator#
	 * getFileTypeDescription()
	 */
	@Override
	public String getFileTypeDescription() {
		return "XSLT Stylesheet";
	}

	/*
	 * (non-Javadoc)
	 * 
	 * @see au.gov.diac.oxygen.plugins.batchvalidator.FileValidator#
	 * getFilenameFilterPattern()
	 */
	@Override
	public String getFilenameFilterPattern() {
		return ".*\\.(xsl|xslt)";
	}

	/*
	 * (non-Javadoc)
	 * 
	 * @see au.gov.diac.oxygen.plugins.batchvalidator.FileValidator#
	 * setValidationErrorHandler
	 * (au.gov.diac.oxygen.plugins.batchvalidator.ValidationErrorHandler)
	 */
	@Override
	public void setValidationErrorHandler(ValidationErrorHandler errorHandler) {
		this.errorHandler = errorHandler;

	}
	
	/*
	 * (non-Javadoc)
	 * 
	 * setFile
	 * @param File to be validated
	 */
	public void setFile(String filePath) {
		this.file = new File(filePath);
	}
	
	/*
	 * (non-Javadoc)
	 * 
	 * getFile
	 * @return File to be validated
	 */
	public File getFile() {
		return this.file;
	}
	
	/*
	 * (non-Javadoc)
	 * 
	 * @see
	 * org.dpdirect.batchvalidator.FileValidator#validate(java
	 * .io.File)
	 */
	public void validate() throws Exception {
		if (null == this.file) {
			throw new Exception("No file to validate");
		}
		validate(this.file);
	}

	/*
	 * (non-Javadoc)
	 * 
	 * @see
	 * au.gov.diac.oxygen.plugins.batchvalidator.FileValidator#validate(java
	 * .io.File)
	 */
	@Override
	public void validate(File file) throws Exception {
		// Initialise the error flag.
		hasErrors = false;

		// Determine if the stylesheet if version 1.0 or 2.0.
		String version = XMLTools.evaluateXPath(
				"(/xsl:stylesheet/@version|/xsl:transform/@version)[1]",
				XMLTools.parseDocument(new FileInputStream(file)));
		boolean isVersion2 = false;
		try {
			isVersion2 = "2.0".equals(version.trim());
		} catch (Exception e) {
			// Ignore.
		}
		if (isVersion2 && (false == allowXslt2)) {
			throw new Exception("XSLT Version 2.0 specified in file "
					+ file.getAbsolutePath());
		}

		StreamSource xslSource = new StreamSource(new FileInputStream(file));
		xslSource.setSystemId(file.getAbsolutePath());
		TransformerFactory factory = (isVersion2) ? new net.sf.saxon.TransformerFactoryImpl()
				: TransformerFactory.newInstance();
		// Only load the custom xml error handler if there is a
		// ValidationErrorHandler object for it to make call-backs on.
		if (null != errorHandler) {
			factory.setErrorListener(new CustomErrorListener());
		}
		factory.newTemplates(xslSource);
		if (hasErrors) {
			throw new Exception(
					"One or more validation errors occurred in file "
							+ file.getName());
		}
	}

	/**
	 * A custom error handler for the transformer factory.
	 */
	class CustomErrorListener implements ErrorListener {

		public void warning(TransformerException ex)
				throws TransformerException {
			// if (null != errorHandler) {
			// errorHandler.handleValidationError("[warning=" + ex.toString()
			// + "]");
			// }
			// hasErrors = true;
		}

		public void error(TransformerException ex) throws TransformerException {
			if (null != errorHandler) {
				errorHandler.handleValidationError("[error=" + ex.toString()
						+ "]");
			}
			hasErrors = true;
		}

		public void fatalError(TransformerException ex)
				throws TransformerException {
			if (null != errorHandler) {
				errorHandler.handleValidationError("[fatal-error="
						+ ex.toString() + "]");
			}
			hasErrors = true;
		}

	}
}
