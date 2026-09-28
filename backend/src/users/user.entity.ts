import { Column, CreateDateColumn, Entity, PrimaryGeneratedColumn } from 'typeorm';
import { TIMESTAMP } from '../config';

export const DEFAULT_ABOUT = 'Hey there! I am using AB Chat.';

@Entity('users')
export class User {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ unique: true })
  phone: string;

  @Column({ default: '' })
  name: string;

  @Column({ default: DEFAULT_ABOUT })
  about: string;

  @Column({ type: TIMESTAMP, nullable: true })
  lastSeenAt: Date | null;

  @CreateDateColumn()
  createdAt: Date;
}
