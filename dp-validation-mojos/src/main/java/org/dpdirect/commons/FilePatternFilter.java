package org.dpdirect.commons;

import java.io.File;
import java.io.FileFilter;

/**
 * A FileFilter class to identify files that match a given file-name filter
 * (regular expression) pattern.
 * 
 * @author N.A.
 */
public class FilePatternFilter implements FileFilter {

	/**
	 * The file name filter (regular expression) pattern.
	 */
	private String filenameFilterPattern = null;
	
	/**
	 * Gets a normalised representation of a directory path (with respect to
	 * path separators).
	 * 
	 * @param path
	 *            the path to normalise.
	 * 
	 * @param encodeSpaces
	 *            flag to indicate whether to encode single space characters
	 *            with the "%20" url encoding replacement.
	 * 
	 * @return a normalised representation of the path.
	 */
	public static String normaliseDirPath(String path, boolean encodeSpaces) {
		if (null == path) {
			return null;
		} else {
			String normalisedPath = normalise(path, encodeSpaces);
			if (!normalisedPath.endsWith("/")) {
				normalisedPath += "/";
			}
			return normalisedPath;
		}
	}
	
	/**
	 * Gets a normalised representation of a file path (with respect to path
	 * separators).
	 * 
	 * @param path
	 *            the path to normalise.
	 * 
	 * @param encodeSpaces
	 *            flag to indicate whether to encode single space characters
	 *            with the "%20" url encoding replacement.
	 * 
	 * @return a normalised representation of the path.
	 */
	public static String normaliseFilePath(String path, boolean encodeSpaces) {
		if (null == path) {
			return null;
		} else {
			return normalise(path, encodeSpaces);
		}
	}

	/**
	 * Gets a normalised representation of a file or directory path (with
	 * respect to path separators).
	 * 
	 * @param path
	 *            the path to normalise.
	 * 
	 * @param encodeSpaces
	 *            flag to indicate whether to encode single space characters
	 *            with the "%20" url encoding replacement.
	 * 
	 * @return a normalised representation of the path.
	 */
	private static String normalise(String path, boolean encodeSpaces) {
		if (null == path) {
			return null;
		} else {
			String normalisedPath = path.replaceAll("[/\\\\]+", "/").trim();
			if (encodeSpaces) {
				normalisedPath = normalisedPath.replaceAll(" ", "%20");
			}
			return normalisedPath;
		}
	}

	public FilePatternFilter(String filenameFilterPattern) {
		if (null != filenameFilterPattern
				&& 0 < filenameFilterPattern.trim().length()) {
			this.filenameFilterPattern = filenameFilterPattern;
		}
	}

	/**
	 * Gets the file name filter pattern.
	 * 
	 * @return the file name filter pattern.
	 */
	public String getFilenameFilterPattern() {
		return filenameFilterPattern;
	}

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
			if (file.isFile() && null != filenameFilterPattern) {
				// Starting the expression with (?i) makes it
				// case-insensitive.
				String regex = "(?i)" + filenameFilterPattern;
				return file.getName().matches(regex);
			} else {
				return false;
			}
		} catch (Exception e) {
			return false;
		}
	}
}