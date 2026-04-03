package com.banking.service;

import com.banking.dto.request.LoginRequest;
import com.banking.dto.request.RegisterRequest;
import com.banking.dto.response.AuthResponse;
import com.banking.entity.Account;
import com.banking.entity.User;
import com.banking.exception.BadRequestException;
import com.banking.security.JwtService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.crypto.password.PasswordEncoder;

import java.math.BigDecimal;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class AuthServiceTest {

    @Mock
    private UserService userService;

    @Mock
    private AccountService accountService;

    @Mock
    private PasswordEncoder passwordEncoder;

    @Mock
    private JwtService jwtService;

    @Mock
    private AuthenticationManager authenticationManager;

    @InjectMocks
    private AuthService authService;

    private RegisterRequest registerRequest;
    private LoginRequest loginRequest;
    private User savedUser;

    @BeforeEach
    void setUp() {
        registerRequest = new RegisterRequest();
        registerRequest.setFirstName("Kwasi");
        registerRequest.setLastName("Boateng");
        registerRequest.setEmail("kwasi@example.com");
        registerRequest.setPassword("password123");
        registerRequest.setPhoneNumber("0240000000");
        registerRequest.setAddress("Accra");

        loginRequest = new LoginRequest();
        loginRequest.setEmail("kwasi@example.com");
        loginRequest.setPassword("password123");

        savedUser = User.builder()
                .id(1L)
                .firstName("Kwasi")
                .lastName("Boateng")
                .email("kwasi@example.com")
                .password("encodedPassword")
                .phoneNumber("0240000000")
                .address("Accra")
                .role(User.Role.USER)
                .enabled(true)
                .accountLocked(false)
                .twoFactorEnabled(false)
                .build();
    }

    @Test
    void register_shouldCreateUserAccountAndReturnAuthResponse() {
        when(userService.existsByEmail(registerRequest.getEmail())).thenReturn(false);
        when(userService.existsByPhoneNumber(registerRequest.getPhoneNumber())).thenReturn(false);
        when(passwordEncoder.encode(registerRequest.getPassword())).thenReturn("encodedPassword");
        when(userService.saveUser(any(User.class))).thenReturn(savedUser);
        when(accountService.existsByAccountNumber(anyString())).thenReturn(false);
        when(jwtService.generateToken(savedUser)).thenReturn("jwt-token");

        AuthResponse response = authService.register(registerRequest);

        assertNotNull(response);
        assertEquals("jwt-token", response.getToken());
        assertEquals("Bearer", response.getType());
        assertEquals(savedUser.getId(), response.getUserId());
        assertEquals(savedUser.getEmail(), response.getEmail());
        assertEquals(savedUser.getFirstName(), response.getFirstName());
        assertEquals(savedUser.getLastName(), response.getLastName());

        ArgumentCaptor<User> userCaptor = ArgumentCaptor.forClass(User.class);
        verify(userService).saveUser(userCaptor.capture());
        User userToSave = userCaptor.getValue();

        assertEquals("Kwasi", userToSave.getFirstName());
        assertEquals("Boateng", userToSave.getLastName());
        assertEquals("kwasi@example.com", userToSave.getEmail());
        assertEquals("encodedPassword", userToSave.getPassword());
        assertEquals("0240000000", userToSave.getPhoneNumber());
        assertEquals("Accra", userToSave.getAddress());
        assertEquals(User.Role.USER, userToSave.getRole());
        assertTrue(userToSave.isEnabled());

        ArgumentCaptor<Account> accountCaptor = ArgumentCaptor.forClass(Account.class);
        verify(accountService).saveAccount(accountCaptor.capture());
        Account savedAccount = accountCaptor.getValue();

        assertNotNull(savedAccount.getAccountNumber());
        assertEquals(10, savedAccount.getAccountNumber().length());
        assertEquals(Account.AccountType.CHECKING, savedAccount.getAccountType());
        assertEquals(BigDecimal.ZERO, savedAccount.getBalance());
        assertEquals("USD", savedAccount.getCurrency());
        assertEquals(Account.AccountStatus.ACTIVE, savedAccount.getStatus());
        assertEquals(savedUser, savedAccount.getUser());
    }

    @Test
    void register_shouldThrowExceptionWhenEmailAlreadyExists() {
        when(userService.existsByEmail(registerRequest.getEmail())).thenReturn(true);

        BadRequestException exception = assertThrows(
                BadRequestException.class,
                () -> authService.register(registerRequest)
        );

        assertEquals("Email already registered", exception.getMessage());
        verify(userService, never()).saveUser(any(User.class));
        verify(accountService, never()).saveAccount(any(Account.class));
        verify(jwtService, never()).generateToken(any(User.class));
    }

    @Test
    void register_shouldThrowExceptionWhenPhoneNumberAlreadyExists() {
        when(userService.existsByEmail(registerRequest.getEmail())).thenReturn(false);
        when(userService.existsByPhoneNumber(registerRequest.getPhoneNumber())).thenReturn(true);

        BadRequestException exception = assertThrows(
                BadRequestException.class,
                () -> authService.register(registerRequest)
        );

        assertEquals("Phone number already registered", exception.getMessage());
        verify(userService, never()).saveUser(any(User.class));
        verify(accountService, never()).saveAccount(any(Account.class));
        verify(jwtService, never()).generateToken(any(User.class));
    }

    @Test
    void login_shouldAuthenticateAndReturnAuthResponse() {
        when(userService.getUserByEmail(loginRequest.getEmail())).thenReturn(savedUser);
        when(jwtService.generateToken(savedUser)).thenReturn("jwt-token");

        AuthResponse response = authService.login(loginRequest);

        verify(authenticationManager).authenticate(
                any(UsernamePasswordAuthenticationToken.class)
        );

        assertNotNull(response);
        assertEquals("jwt-token", response.getToken());
        assertEquals("Bearer", response.getType());
        assertEquals(savedUser.getId(), response.getUserId());
        assertEquals(savedUser.getEmail(), response.getEmail());
        assertEquals(savedUser.getFirstName(), response.getFirstName());
        assertEquals(savedUser.getLastName(), response.getLastName());
    }
}