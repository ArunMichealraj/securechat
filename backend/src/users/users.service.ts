import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { In, Repository } from 'typeorm';
import { User } from './user.entity';

@Injectable()
export class UsersService {
  constructor(@InjectRepository(User) private readonly users: Repository<User>) {}

  async findOrCreateByPhone(phone: string): Promise<User> {
    const existing = await this.users.findOneBy({ phone });
    return existing ?? this.users.save(this.users.create({ phone }));
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
