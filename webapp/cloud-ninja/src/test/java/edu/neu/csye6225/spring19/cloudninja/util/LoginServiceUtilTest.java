package edu.neu.csye6225.spring19.cloudninja.util;

import static org.junit.Assert.assertTrue;

import org.junit.Test;

import edu.neu.csye6225.spring19.cloudninja.exception.ValidationException;

public class LoginServiceUtilTest {
//    @Autowired
	private AuthServiceUtil authServiceUtil = new AuthServiceUtil();

	@Test
	public void checkPasswordStrength() {
		boolean flag = false;
		try {
			authServiceUtil.checkPasswordStrength("MansOi@123");
			flag = true;
		} catch (ValidationException e) {
			e.printStackTrace();
		} finally {
			assertTrue(flag);
		}

	}

	@Test
	public void isValidEmail() {

		boolean flag = false;
		try {
			authServiceUtil.isValidEmail("mansi@gmail.com");
			flag = true;
		} catch (ValidationException e) {
			e.printStackTrace();
		} finally {
			assertTrue(flag);
		}

	}
}