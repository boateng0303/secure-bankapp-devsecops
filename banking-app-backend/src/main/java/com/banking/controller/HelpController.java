package com.banking.controller;

import com.banking.dto.response.ApiResponse;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/help")
public class HelpController {

    @GetMapping
    public ResponseEntity<ApiResponse<Map<String, Object>>> getHelp() {
        Map<String, Object> helpData = new HashMap<>();
        
        helpData.put("contactEmail", "support@securebanking.com");
        helpData.put("contactPhone", "+1-800-123-4567");
        helpData.put("supportHours", "Monday - Friday: 9:00 AM - 6:00 PM EST");
        
        Map<String, String> faqs = new HashMap<>();
        faqs.put("How do I transfer money?", "Go to Money/Transfer page, select your account, enter recipient details and amount.");
        faqs.put("How do I add a beneficiary?", "Navigate to Beneficiaries page and click 'Add Beneficiary' button.");
        faqs.put("How do I change my password?", "Go to Profile > Security Settings and click 'Change Password'.");
        faqs.put("What should I do if I forget my password?", "Click 'Forgot Password' on the login page and follow the instructions.");
        faqs.put("How do I enable two-factor authentication?", "Go to Profile > Security Settings and toggle the 2FA option.");
        
        helpData.put("faqs", faqs);
        
        return ResponseEntity.ok(ApiResponse.success("Help information retrieved successfully", helpData));
    }
}

