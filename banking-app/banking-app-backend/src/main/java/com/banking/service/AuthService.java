package com.banking.service;

import com.banking.dto.request.LoginRequest;
import com.banking.dto.request.RegisterRequest;
import com.banking.dto.response.AuthResponse;
import com.banking.entity.Account;
import com.banking.entity.User;
import com.banking.exception.BadRequestException;
import com.banking.security.JwtService;
import lombok.RequiredArgsConstructor;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.Random;

@Service
@RequiredArgsConstructor
public class AuthService {

    private final UserService userService;
    private final AccountService accountService;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;
    private final AuthenticationManager authenticationManager;

    @Transactional
    public AuthResponse register(RegisterRequest request) {
        // Check if user already exists
        if (userService.existsByEmail(request.getEmail())) {
            throw new BadRequestException("Email already registered");
        }

        if (userService.existsByPhoneNumber(request.getPhoneNumber())) {
            throw new BadRequestException("Phone number already registered");
        }

        // Create user
        User user = User.builder()
                .firstName(request.getFirstName())
                .lastName(request.getLastName())
                .email(request.getEmail())
                .password(passwordEncoder.encode(request.getPassword()))
                .phoneNumber(request.getPhoneNumber())
                .address(request.getAddress())
                .role(User.Role.USER)
                .twoFactorEnabled(false)
                .accountLocked(false)
                .enabled(true)
                .build();

        user = userService.saveUser(user);

        // Create default checking account for the user
        Account account = Account.builder()
                .accountNumber(generateAccountNumber())
                .accountType(Account.AccountType.CHECKING)
                .balance(BigDecimal.ZERO)
                .currency("USD")
                .status(Account.AccountStatus.ACTIVE)
                .user(user)
                .build();

        accountService.saveAccount(account);

        // Generate JWT token
        String jwtToken = jwtService.generateToken(user);

        return AuthResponse.builder()
                .token(jwtToken)
                .type("Bearer")
                .userId(user.getId())
                .email(user.getEmail())
                .firstName(user.getFirstName())
                .lastName(user.getLastName())
                .build();
    }

    public AuthResponse login(LoginRequest request) {
        authenticationManager.authenticate(
                new UsernamePasswordAuthenticationToken(
                        request.getEmail(),
                        request.getPassword()
                )
        );

        User user = userService.getUserByEmail(request.getEmail());
        String jwtToken = jwtService.generateToken(user);

        return AuthResponse.builder()
                .token(jwtToken)
                .type("Bearer")
                .userId(user.getId())
                .email(user.getEmail())
                .firstName(user.getFirstName())
                .lastName(user.getLastName())
                .build();
    }

    private String generateAccountNumber() {
        Random random = new Random();
        StringBuilder accountNumber = new StringBuilder();
        for (int i = 0; i < 10; i++) {
            accountNumber.append(random.nextInt(10));
        }
        
        // Check if account number already exists
        if (accountService.existsByAccountNumber(accountNumber.toString())) {
            return generateAccountNumber(); // Recursively generate new number
        }
        
        return accountNumber.toString();
    }
}

