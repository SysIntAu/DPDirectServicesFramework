package org.dpdirect.batchvalidator;

import java.io.File;

import javax.wsdl.factory.WSDLFactory;
import javax.wsdl.xml.WSDLReader;

import org.apache.maven.plugin.MojoExecutionException;

import org.dpdirect.dp.AbstractDPMojo;

/**
 * A file validator for WSDL 1.1 files.
 * 
 * @author N.A.
 * 
 * @goal wsdlValidate
 * @phase compile
 * @requiresDependencyResolution
 */
public class WSDLValidatorMojo extends AbstractDPMojo
{
    /**
     * A flag to indicate the occurrence of errors.
     */
    private boolean hasErrors = false;

    @Override
    public void execute() throws MojoExecutionException
    {
        performNamespaceBinding();
        try
        {
            String[] srcFiles = retrieveSchemaFiles();
            for (String srcFile : srcFiles)
            {
                File wsdlToValidate = new File(buildDirectory, srcFile);
                getLog().debug("Validating WSDL: " + wsdlToValidate);
                this.setValidationErrorHandler(new ValidationErrorHandler()
                {
                    @Override
                    public void handleValidationError(String msg)
                    {
                        getLog().error("Validation Error: " + msg);
                    }
                });
                validate(wsdlToValidate);
                validateDependencies(wsdlToValidate);
                getLog().info(wsdlToValidate + " successfully validated.");
            }
        }
        catch (Exception e)
        {
            throw new MojoExecutionException(e.getMessage(), e);
        }
    }

    /*
     * (non-Javadoc)
     * @see org.dpdirect.batchvalidator.FileValidator# getFileTypeDescription()
     */
    @Override
    public String getFileTypeDescription()
    {
        return "WSDL 1.1";
    }

    /*
     * (non-Javadoc)
     * @see org.dpdirect.batchvalidator.FileValidator# getFilenameFilterPattern()
     */
    @Override
    public String getFilenameFilterPattern()
    {
        return ".*\\.wsdl";
    }

    /*
     * (non-Javadoc)
     * @see org.dpdirect.batchvalidator.FileValidator#validate(java .io.File)
     */
    @Override
    public void validate(File file) throws Exception
    {
        // Initialise the error flag.
        hasErrors = false;

        WSDLFactory wsdlFactory = WSDLFactory.newInstance();
        WSDLReader wsdlReader = wsdlFactory.newWSDLReader();
        try
        {
            wsdlReader.readWSDL(file.getAbsolutePath());
        }
        catch (Exception ex)
        {
            hasErrors = true;
            if (null != errorHandler)
            {
                errorHandler.handleValidationError("[error=" + ex.toString() + "]");
            }
        }
        if (hasErrors)
        {
            throw new Exception("One or more validation errors occured in file '" + file.getName() + "' [full-path: "
                                + file.getAbsolutePath() + "]");
        }
    }
}
