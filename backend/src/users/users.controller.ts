import { Body, Controller, Get, Param, ParseUUIDPipe, Patch, Post, UseGuards } from '@nestjs/common';
import { ArrayMaxSize, IsArray, IsOptional, IsString, MaxLength } from 'class-validator';
import { CurrentUserId, JwtAuthGuard } from '../common/jwt-auth.guard';
import { normalizePhone } from '../common/phone';
import { UsersService } from './users.service';

class UpdateProfileDto {
  @IsOptional() @IsString() @MaxLength(50)
  name?: string;

  @IsOptional() @IsString() @MaxLength(140)
  about?: string;
}

class LookupDto {
  @IsArray() @ArrayMaxSize(1000) @IsString({ each: true })
  phones: string[];
}

@Controller('users')
@UseGuards(JwtAuthGuard)
export class UsersController {
  constructor(private readonly users: UsersService) {}

  @Get('me')
  me(@CurrentUserId() userId: string) {
    return this.users.get(userId);
  }

  @Patch('me')
  updateMe(@CurrentUserId() userId: string, @Body() dto: UpdateProfileDto) {
    return this.users.update(userId, dto);
  }

  // Returns which of the given phone numbers are registered (used for "new chat" and contact sync).
  @Post('lookup')
  lookup(@Body() dto: LookupDto) {
    const phones = dto.phones.flatMap((p) => {
      try {
        return [normalizePhone(p)];
      } catch {
        return [];
      }
    });
    return this.users.findByPhones(phones);
  }

  @Get(':id')
  get(@Param('id', ParseUUIDPipe) id: string) {
    return this.users.get(id);
  }
}
