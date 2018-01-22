package org.dpdirect.commons;

import java.io.File;
import java.io.FileFilter;

/**
 * A FileFilter class to accept only directories.
 * 
 * @author N.A.
 */
public class DirectoryFilter implements FileFilter {

	/**
	 * Tests whether or not the specified file should be included in a file
	 * list.
	 * 
	 * @param file
	 *            The file to be tested
	 * @return <code>true</code> if and only if the file should be included
	 */
	public boolean accept(File file) {
		try {
			if (file.isDirectory()) {
				return true;
			} else {
				return false;
			}
		} catch (Exception e) {
			return false;
		}
	}
}