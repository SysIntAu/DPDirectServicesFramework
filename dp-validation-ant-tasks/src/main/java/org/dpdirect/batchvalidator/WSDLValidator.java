package org.dpdirect.batchvalidator;

import java.io.File;
import java.util.HashMap;
import java.util.List;
import org.dpdirect.commons.XMLTools;
import org.dpdirect.commons.FilePatternFilter;
import javax.wsdl.factory.WSDLFactory;
import javax.wsdl.xml.WSDLReader;
import org.apache.tools.ant.BuildException;
import org.apache.tools.ant.Task;

/**
 * A file validator for WSDL 1.1 files.
 * 
 * @author N.A.
 */
public class WSDLValidator extends Task implements FileValidator {

	/**
	 * A flag to indicate the occurrence of errors.
	 */
	private boolean hasErrors = false;
	
	private File file = null;

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
	 * Constructs a new <code>WSDLValidator</code> object.
	 */
	public WSDLValidator() {
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

	/*
	 * (non-Javadoc)
	 * 
	 * @see org.dpdirect.batchvalidator.FileValidator#
	 * getFileTypeDescription()
	 */
	@Override
	public String getFileTypeDescription() {
		return "WSDL 1.1";
	}

	/*
	 * (non-Javadoc)
	 * 
	 * @see org.dpdirect.batchvalidator.FileValidator#
	 * getFilenameFilterPattern()
	 */
	@Override
	public String getFilenameFilterPattern() {
		return ".*\\.wsdl";
	}

	/*
	 * (non-Javadoc)
	 * 
	 * @see org.dpdirect.batchvalidator.FileValidator#
	 * setValidationErrorHandler
	 * (org.dpdirect.batchvalidator.ValidationErrorHandler)
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
	 * org.dpdirect.batchvalidator.FileValidator#validate(java
	 * .io.File)
	 */
	@Override
	public void validate(File file) throws Exception {
		// Initialise the error flag.
		hasErrors = false;

		WSDLFactory wsdlFactory = WSDLFactory.newInstance();
		WSDLReader wsdlReader = wsdlFactory.newWSDLReader();
		try {
			wsdlReader.readWSDL(file.getAbsolutePath());
		} catch (Exception ex) {
			hasErrors = true;
			if (null != errorHandler) {
				errorHandler.handleValidationError("[error=" + ex.toString()
						+ "]");
			}
		}
		if (hasErrors) {
			throw new Exception(
					"One or more validation errors occured in file '"
							+ file.getName() + "' [full-path: "
							+ file.getAbsolutePath() + "]");
		}
	}
}
