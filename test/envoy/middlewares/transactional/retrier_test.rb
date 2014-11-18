require_relative '../../../test_helper'
require_relative '../../../../lib/envoy/middlewares/transactional/retrier'

describe Envoy::Middlewares::Transactional::Retrier do
  before do
    @retrier = described_class.new
  end

  it 'retries deadlock errors' do
    tries = 0

    begin
      @retrier.call do
        tries += 1

        fail ActiveRecord::StatementInvalid, 'PG::TRDeadlockDetected: '\
          'ERROR: deadlock detected '\
          'DETAIL: Process 1105 waits for ShareLock on transaction 1197700; blocked b.... '\
          'Process 1043 waits for ShareLock on transaction 1197560; blocked by process 1105. '\
          'HINT: See server log for query details.'
      end
    rescue ActiveRecord::StatementInvalid
    end

    tries.must_equal 10
  end

  it 'retries serializable errors' do
    tries = 0

    begin
      @retrier.call do
        tries += 1

        fail ActiveRecord::StatementInvalid, 'PG::TRSerializationFailure: '\
          'ERROR: could not serialize access due to read/write dependencies among transactions '\
          'DETAIL: Reason code: Canceled on identification as a pivot, during conflict in checking. '\
          'HINT: The transaction might succeed if retried.'
      end
    rescue ActiveRecord::StatementInvalid
    end

    tries.must_equal 10
  end

  it 'retries unique key conflicts' do
    tries = 0

    begin
      @retrier.call do
        tries += 1

        fail ActiveRecord::RecordNotUnique, 'PGError: '\
          'ERROR: duplicate key value violates unique constraint.'
      end
    rescue ActiveRecord::RecordNotUnique
    end

    tries.must_equal 10
  end
end
