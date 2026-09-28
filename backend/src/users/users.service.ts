import { Injectable, NotFoundException, OnModuleInit } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { In, Repository } from 'typeorm';
import { DEFAULT_ABOUT, User } from './user.entity';

// Default "about" text from before the app was renamed.
const OLD_DEFAULT_ABOUT = 'Hey there! I am using SecureChat.';

@Injectable()
export class UsersService implements OnModuleInit {
  constructor(@InjectRepository(User) private readonly users: Repository<User>) {}

  // Users who never edited their "about" still have the old app name in it.
  async onModuleInit() {
    await this.users.update({ about: OLD_DEFAULT_ABOUT }, { about: DEFAULT_ABOUT });
  }

  async findOrCreateByPhone(phone: string): Promise<User> {
    const existing = await this.users.findOneBy({ phone });
    // Set explicitly: an existing database keeps its old column default even after the code changes.
    return existing ?? this.users.save(this.users.create({ phone, about: DEFAULT_ABOUT }));
  }

  async get(id: string): Promise<User> {
    const user = await this.users.findOneBy({ id });
    if (!user) throw new NotFoundException('User not found');
    return user;
  }

  findMany(ids: string[]): Promise<User[]> {
    return ids.length ? this.users.findBy({ id: In(ids) }) : Promise.resolve([]);
  }

  findByPhones(phones: string[]): Promise<User[]> {
    return phones.length ? this.users.findBy({ phone: In(phones) }) : Promise.resolve([]);
  }

  async update(id: string, changes: Partial<Pick<User, 'name' | 'about'>>): Promise<User> {
    await this.users.update(id, changes);
    return this.get(id);
  }

  async touchLastSeen(id: string): Promise<Date> {
    const now = new Date();
    await this.users.update(id, { lastSeenAt: now });
    return now;
  }
}
