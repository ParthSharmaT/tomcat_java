package com.example.hello_world_Java.controller;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;

@Controller
public class Hello_WorldController {

    @GetMapping("/")
    public String index() {
        return "index"; 
    }
}



