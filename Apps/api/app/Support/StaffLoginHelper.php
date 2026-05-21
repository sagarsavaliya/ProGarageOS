<?php

namespace App\Support;

use App\Models\User;

class StaffLoginHelper
{
    public static function phoneCandidates(string $login): array
    {
        $login = trim($login);
        $candidates = [$login];

        if (preg_match('/^\d{10}$/', $login)) {
            $candidates[] = '+91' . $login;
        }

        if (str_starts_with($login, '+91') && strlen($login) === 13) {
            $candidates[] = substr($login, 3);
        }

        return array_values(array_unique($candidates));
    }

    public static function findByLogin(string $login): ?User
    {
        $candidates = self::phoneCandidates($login);

        return User::with('tenant')
            ->where(function ($query) use ($login, $candidates) {
                $query->where('email', $login)
                    ->orWhereIn('phone', $candidates);
            })
            ->first();
    }

    public static function normalizePhone(string $phone): string
    {
        $digits = preg_replace('/\D/', '', $phone);

        if (strlen($digits) >= 12) {
            return '+' . $digits;
        }

        if (strlen($digits) === 10) {
            return '+91' . $digits;
        }

        return '+' . $digits;
    }
}
