package com.banking.controller;

import com.banking.dto.request.ChangePasswordRequest;
import com.banking.dto.request.UpdateProfileRequest;
import com.banking.dto.response.ApiResponse;
import com.banking.dto.response.UserResponse;
import com.banking.entity.User;
import com.banking.exception.BadRequestException;
import com.banking.service.UserService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/profile")
@RequiredArgsConstructor
public class ProfileController {

    private final UserService userService;
    private final PasswordEncoder passwordEncoder;

    @GetMapping
    public ResponseEntity<ApiResponse<UserResponse>> getProfile(@AuthenticationPrincipal User user) {
        UserResponse response = mapToUserResponse(user);
        return ResponseEntity.ok(ApiResponse.success("Profile retrieved successfully", response));
    }

    @PutMapping
    public ResponseEntity<ApiResponse<UserResponse>> updateProfile(
            @Valid @RequestBody UpdateProfileRequest request,
            @AuthenticationPrincipal User user) {

        if (request.getFirstName() != null) {
            user.setFirstName(request.getFirstName());
        }
        if (request.getLastName() != null) {
            user.setLastName(request.getLastName());
        }
        if (request.getPhoneNumber() != null) {
            // Check if phone number is already taken by another user
            if (userService.existsByPhoneNumber(request.getPhoneNumber()) &&
                    !user.getPhoneNumber().equals(request.getPhoneNumber())) {
                throw new BadRequestException("Phone number already in use");
            }
            user.setPhoneNumber(request.getPhoneNumber());
        }
        if (request.getAddress() != null) {
            user.setAddress(request.getAddress());
        }

        User updatedUser = userService.saveUser(user);
        return ResponseEntity.ok(ApiResponse.success("Profile updated successfully", mapToUserResponse(updatedUser)));
    }

    @PostMapping("/change-password")
    public ResponseEntity<ApiResponse<Void>> changePassword(
            @Valid @RequestBody ChangePasswordRequest request,
            @AuthenticationPrincipal User user) {

        // Verify current password
        if (!passwordEncoder.matches(request.getCurrentPassword(), user.getPassword())) {
            throw new BadRequestException("Current password is incorrect");
        }

        // Update password
        user.setPassword(passwordEncoder.encode(request.getNewPassword()));
        userService.saveUser(user);

        return ResponseEntity.ok(ApiResponse.success("Password changed successfully", null));
    }

    @PostMapping("/toggle-2fa")
    public ResponseEntity<ApiResponse<UserResponse>> toggle2FA(@AuthenticationPrincipal User user) {
        user.setTwoFactorEnabled(!user.getTwoFactorEnabled());
        User updatedUser = userService.saveUser(user);
        
        String message = updatedUser.getTwoFactorEnabled() ? 
                "Two-factor authentication enabled" : "Two-factor authentication disabled";
        
        return ResponseEntity.ok(ApiResponse.success(message, mapToUserResponse(updatedUser)));
    }

    private UserResponse mapToUserResponse(User user) {
        return UserResponse.builder()
                .id(user.getId())
                .firstName(user.getFirstName())
                .lastName(user.getLastName())
                .email(user.getEmail())
                .phoneNumber(user.getPhoneNumber())
                .address(user.getAddress())
                .twoFactorEnabled(user.getTwoFactorEnabled())
                .createdAt(user.getCreatedAt())
                .build();
    }
}

