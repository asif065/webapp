<?php


test('registration screen redirects to login', function () {
    $response = $this->get(route('register'));

    $response->assertRedirect(route('login'));
});

test('new users can register', function () {
    $response = $this->post(route('register.store'), [
        'name' => 'Test User',
        'email' => 'test@example.com',
        'password' => 'password',
        'password_confirmation' => 'password',
    ]);

    // Fortify typically redirects after successful registration
    $response->assertRedirect();

    $this->assertDatabaseHas('users', [
        'email' => 'test@example.com',
    ]);
});